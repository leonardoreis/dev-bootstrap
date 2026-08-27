#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] GIT / SSH ==="

# ------------------------------------------------------------
# Identidade Git
# ------------------------------------------------------------

CURRENT_NAME="$(git config --global user.name 2>/dev/null || true)"
CURRENT_EMAIL="$(git config --global user.email 2>/dev/null || true)"

echo
echo "==> Configuração de identidade Git"

if [ -n "$CURRENT_NAME" ]; then
    read -rp "Nome para commits [$CURRENT_NAME]: " GIT_NAME
    GIT_NAME="${GIT_NAME:-$CURRENT_NAME}"
else
    read -rp "Nome para commits: " GIT_NAME
fi

if [ -n "$CURRENT_EMAIL" ]; then
    read -rp "E-mail para commits [$CURRENT_EMAIL]: " GIT_EMAIL
    GIT_EMAIL="${GIT_EMAIL:-$CURRENT_EMAIL}"
else
    read -rp "E-mail para commits: " GIT_EMAIL
fi

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo
echo "[OK] Git configurado:"
echo "     Nome  : $(git config --global user.name)"
echo "     E-mail: $(git config --global user.email)"

# ------------------------------------------------------------
# SSH
# ------------------------------------------------------------

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then

    echo
    echo "==> Criando chave SSH desta estação..."

    ssh-keygen \
        -t ed25519 \
        -C "$GIT_EMAIL" \
        -f "$HOME/.ssh/id_ed25519"

    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"

else
    echo
    echo "[OK] Chave SSH existente encontrada."
fi

# ------------------------------------------------------------
# SSH Agent persistente
# ------------------------------------------------------------

SSH_AGENT_SOCKET="$HOME/.ssh/agent.sock"

if [ -S "$SSH_AGENT_SOCKET" ]; then
    if ! SSH_AUTH_SOCK="$SSH_AGENT_SOCKET" ssh-add -l >/dev/null 2>&1; then
        rm -f "$SSH_AGENT_SOCKET"
    fi
fi

if [ ! -S "$SSH_AGENT_SOCKET" ]; then
    echo
    echo "==> Iniciando ssh-agent..."

    eval "$(ssh-agent -a "$SSH_AGENT_SOCKET" -s)" >/dev/null
fi

export SSH_AUTH_SOCK="$SSH_AGENT_SOCKET"

if ! ssh-add -l >/dev/null 2>&1; then
    echo
    echo "==> Carregando chave SSH por 8 horas..."
    ssh-add -t 8h "$HOME/.ssh/id_ed25519"
fi

# ------------------------------------------------------------
# Cadastro no GitHub
# ------------------------------------------------------------

echo
echo "============================================================"
echo " CHAVE SSH PÚBLICA DESTA MÁQUINA"
echo "============================================================"
echo
cat "$HOME/.ssh/id_ed25519.pub"
echo
echo "============================================================"
echo
echo "Cadastre esta chave no GitHub:"
echo
echo "Settings -> SSH and GPG keys -> New SSH key"
echo
echo "Sugestão de nome: $(hostname)"
echo

while true; do

    read -rp "Pressione ENTER depois de cadastrar a chave no GitHub..."

    echo
    echo "==> Testando autenticação com GitHub..."

    SSH_RESULT="$(ssh \
        -o StrictHostKeyChecking=accept-new \
        -T git@github.com 2>&1 || true)"

    if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
        echo
        echo "[OK] GitHub reconheceu esta máquina."
        break
    fi

    echo
    echo "[PENDENTE] GitHub ainda não reconheceu a chave."
    echo
    echo "$SSH_RESULT"
    echo
done

echo
echo "[OK] Git / SSH completamente configurados."