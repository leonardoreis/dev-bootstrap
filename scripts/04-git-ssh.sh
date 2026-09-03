#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] CONFIGURAÇÃO GIT + SSH ==="

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
PUB_KEY="$SSH_KEY.pub"
AGENT_SOCK="$SSH_DIR/agent.sock"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ------------------------------------------------------------
# 1. Identidade Git Global (Pergunta se estiver vazio)
# ------------------------------------------------------------

CURRENT_NAME="$(git config --global user.name || true)"
CURRENT_EMAIL="$(git config --global user.email || true)"

if [ -z "$CURRENT_NAME" ]; then
    read -rp "Nome para o Git (user.name): " GIT_NAME
    git config --global user.name "$GIT_NAME"
else
    echo "[OK] Git user.name já configurado: $CURRENT_NAME"
fi

if [ -z "$CURRENT_EMAIL" ]; then
    read -rp "E-mail para o Git (user.email): " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
else
    echo "[OK] Git user.email já configurado: $CURRENT_EMAIL"
fi

git config --global init.defaultBranch main
git config --global pull.rebase false

echo "[OK] Configuração global do Git concluída."

# ------------------------------------------------------------
# 2. Geração da Chave SSH Ed25519
# ------------------------------------------------------------

if [ -f "$SSH_KEY" ]; then
    echo "[OK] Chave SSH existente: $SSH_KEY"
else
    echo "==> Gerando chave SSH Ed25519..."

    ssh-keygen \
        -t ed25519 \
        -C "$(git config --global user.email)" \
        -f "$SSH_KEY" \
        -N ""

    echo "[OK] Chave SSH criada."
fi

chmod 600 "$SSH_KEY"
chmod 644 "$PUB_KEY"

# ------------------------------------------------------------
# 3. Gerenciamento do SSH Agent Persistente
# ------------------------------------------------------------

if [ -S "$AGENT_SOCK" ]; then
    if SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l >/dev/null 2>&1; then
        export SSH_AUTH_SOCK="$AGENT_SOCK"
        echo "[OK] ssh-agent existente reutilizado."
    else
        echo "==> Socket antigo do ssh-agent inválido. Recriando..."
        rm -f "$AGENT_SOCK"
    fi
fi

if [ ! -S "$AGENT_SOCK" ]; then
    eval "$(ssh-agent -a "$AGENT_SOCK")" >/dev/null
fi

export SSH_AUTH_SOCK="$AGENT_SOCK"

# Validação do Fingerprint para evitar duplicatas no agente
if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$PUB_KEY" | awk '{print $2}')"; then
    echo "[OK] Chave SSH já carregada no ssh-agent."
else
    echo "==> Carregando chave SSH no agente por 8 horas..."
    ssh-add -t 8h "$SSH_KEY"
fi

# ------------------------------------------------------------
# 4. Teste de Conexão com Loop Interativo
# ------------------------------------------------------------

echo
echo "==> Testando autenticação SSH com GitHub..."

check_github() {
    ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -qi "successfully authenticated"
}

if check_github; then
    echo "[OK] GitHub autenticado via SSH."
else
    echo
    echo "============================================================"
    echo " CHAVE SSH PÚBLICA"
    echo " Adicione no GitHub para liberar o clone dos repositórios:"
    echo "============================================================"
    cat "$PUB_KEY"
    echo "============================================================"
    echo
    echo "Passos:"
    echo "1. Acesse: https://github.com/settings/keys"
    echo "2. Clique em 'New SSH key'"
    echo "3. Cole a chave exibida acima e salve"
    echo

    while ! check_github; do
        read -rp "Após adicionar a chave no GitHub, pressione [ENTER] para testar novamente..."
        echo "==> Testando autenticação novamente..."
    done

    echo "[OK] GitHub autenticado via SSH com sucesso!"
fi
