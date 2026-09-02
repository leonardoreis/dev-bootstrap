#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] GIT / SSH ==="

CURRENT_NAME="$(git config --global user.name 2>/dev/null || true)"
CURRENT_EMAIL="$(git config --global user.email 2>/dev/null || true)"

echo "==> Configuração de identidade Git"

GIT_NAME=""
while [ -z "$GIT_NAME" ]; do
    if [ -n "$CURRENT_NAME" ]; then
        read -rp "Nome para commits [$CURRENT_NAME]: " GIT_NAME
        GIT_NAME="${GIT_NAME:-$CURRENT_NAME}"
    else
        read -rp "Nome para commits: " GIT_NAME
    fi
done

GIT_EMAIL=""
while [ -z "$GIT_EMAIL" ]; do
    if [ -n "$CURRENT_EMAIL" ]; then
        read -rp "E-mail para commits [$CURRENT_EMAIL]: " GIT_EMAIL
        GIT_EMAIL="${GIT_EMAIL:-$CURRENT_EMAIL}"
    else
        read -rp "E-mail para commits: " GIT_EMAIL
    fi
done

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo
echo "[OK] Git configurado:"
echo "     Nome  : $(git config --global user.name)"
echo "     E-mail: $(git config --global user.email)"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo
    echo "==> Gerando nova chave SSH (ED25519)..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
else
    echo
    echo "[OK] Chave SSH já existente encontrada em: $SSH_KEY_PATH"
fi

SSH_AGENT_SOCKET="$HOME/.ssh/agent.sock"

# Limpeza e reinicialização segura do agente SSH
if [ -S "$SSH_AGENT_SOCKET" ]; then
    if ! SSH_AUTH_SOCK="$SSH_AGENT_SOCKET" ssh-add -l >/dev/null 2>&1; then
        rm -f "$SSH_AGENT_SOCKET"
    fi
fi

if [ ! -S "$SSH_AGENT_SOCKET" ]; then
    echo "==> Inicializando ssh-agent..."
    eval "$(ssh-agent -a "$SSH_AGENT_SOCKET" -s)" >/dev/null
fi

export SSH_AUTH_SOCK="$SSH_AGENT_SOCKET"

if ! ssh-add -l | grep -q "$SSH_KEY_PATH" 2>/dev/null; then
    echo "==> Adicionando chave SSH ao ssh-agent (8 horas)..."
    ssh-add -t 8h "$SSH_KEY_PATH"
fi

echo
echo "==> Testando conexão SSH com o GitHub..."

SSH_CHECK_CMD() {
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -T git@github.com 2>&1 || true
}

SSH_RESULT="$(SSH_CHECK_CMD)"

if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
    echo "[OK] GitHub autenticado com sucesso."
else
    echo "============================================================"
    echo " CHAVE SSH PÚBLICA (Copie e adicione ao GitHub)"
    echo "============================================================"
    cat "${SSH_KEY_PATH}.pub"
    echo "============================================================"
    echo "URL: https://github.com/settings/keys"
    echo

    while true; do
        read -rp "Pressione ENTER após cadastrar a chave no GitHub..."
        echo "==> Validando conexão..."
        
        SSH_RESULT="$(SSH_CHECK_CMD)"
        if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
            echo "[OK] GitHub reconheceu a chave com sucesso!"
            break
        fi

        echo "[AVISO] Não foi possível autenticar. Detalhes:"
        echo "$SSH_RESULT"
        echo
    done
fi

DEV_BOOTSTRAP_DIR="$HOME/projects/dev-bootstrap"

if [ -d "$DEV_BOOTSTRAP_DIR/.git" ]; then
    git -C "$DEV_BOOTSTRAP_DIR" remote set-url origin git@github.com:leonardoreis/dev-bootstrap.git
    echo "[OK] Repositório dev-bootstrap apontado para o protocolo SSH."
fi

echo
echo "[OK] Etapa Git/SSH finalizada."
