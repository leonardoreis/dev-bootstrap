#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] CONFIGURAÇÃO GIT + SSH ==="

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
PUB_KEY="$SSH_KEY.pub"
SSH_CONFIG="$SSH_DIR/config"
AGENT_SOCK="$SSH_DIR/agent.sock"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ------------------------------------------------------------
# 1. Identidade global do Git
# ------------------------------------------------------------

CURRENT_NAME="$(git config --global user.name || true)"
CURRENT_EMAIL="$(git config --global user.email || true)"

if [ -z "$CURRENT_NAME" ]; then
    read -rp "Nome para o Git (user.name): " GIT_NAME

    if [ -n "$GIT_NAME" ]; then
        git config --global user.name "$GIT_NAME"
    fi
else
    echo "[OK] Git user.name: $CURRENT_NAME"
fi

if [ -z "$CURRENT_EMAIL" ]; then
    read -rp "E-mail para o Git (user.email): " GIT_EMAIL

    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
    fi
else
    echo "[OK] Git user.email: $CURRENT_EMAIL"
fi

git config --global init.defaultBranch main
git config --global pull.rebase false

echo "[OK] Configuração global do Git concluída."

# ------------------------------------------------------------
# 2. Chave SSH
# ------------------------------------------------------------

if [ -f "$SSH_KEY" ]; then
    echo "[OK] Chave SSH existente preservada:"
    echo "     $SSH_KEY"
else
    echo
    echo "==> Nenhuma chave Ed25519 encontrada."
    echo "==> Gerando nova chave SSH..."

    KEY_COMMENT="$(git config --global user.email || true)"

    if [ -z "$KEY_COMMENT" ]; then
        KEY_COMMENT="$USER@$(hostname)"
    fi

    ssh-keygen \
        -t ed25519 \
        -C "$KEY_COMMENT" \
        -f "$SSH_KEY" \
        -N ""

    echo "[OK] Nova chave SSH criada."
fi

chmod 600 "$SSH_KEY"

# Se a chave privada existe, mas o .pub sumiu,
# reconstrói APENAS a chave pública.
if [ ! -f "$PUB_KEY" ]; then
    echo "==> Chave pública ausente. Reconstruindo a partir da chave privada..."
    ssh-keygen -y -f "$SSH_KEY" > "$PUB_KEY"
fi

chmod 644 "$PUB_KEY"

# ------------------------------------------------------------
# 3. Configuração SSH específica para GitHub
# ------------------------------------------------------------

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSH_CONFIG"; then
    echo
    echo "==> Configurando identidade SSH para GitHub..."

    cat >> "$SSH_CONFIG" <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF

    echo "[OK] GitHub configurado em ~/.ssh/config."
else
    echo "[OK] Configuração SSH para github.com já existe."
fi

# ------------------------------------------------------------
# 4. SSH Agent
# ------------------------------------------------------------

if [ -S "$AGENT_SOCK" ]; then
    if SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l >/dev/null 2>&1; then
        export SSH_AUTH_SOCK="$AGENT_SOCK"
        echo "[OK] ssh-agent existente reutilizado."
    else
        echo "==> Socket antigo do ssh-agent encontrado. Recriando..."
        rm -f "$AGENT_SOCK"
    fi
fi

if [ ! -S "$AGENT_SOCK" ]; then
    eval "$(ssh-agent -a "$AGENT_SOCK")" >/dev/null
    echo "[OK] ssh-agent iniciado."
fi

export SSH_AUTH_SOCK="$AGENT_SOCK"

KEY_FINGERPRINT="$(ssh-keygen -lf "$PUB_KEY" | awk '{print $2}')"

if ssh-add -l 2>/dev/null | grep -Fq "$KEY_FINGERPRINT"; then
    echo "[OK] Chave já carregada no ssh-agent."
else
    echo "==> Carregando chave no ssh-agent..."

    if ssh-add "$SSH_KEY"; then
        echo "[OK] Chave carregada no ssh-agent."
    else
        echo "[AVISO] Não foi possível carregar a chave no ssh-agent."
        echo "        O SSH ainda poderá usar o arquivo diretamente."
    fi
fi

# ------------------------------------------------------------
# 5. Teste real de autenticação no GitHub
# ------------------------------------------------------------

echo
echo "==> Testando autenticação SSH com GitHub..."

check_github() {
    local output

    output="$(
        ssh \
            -o BatchMode=yes \
            -o ConnectTimeout=10 \
            -o StrictHostKeyChecking=accept-new \
            -T git@github.com 2>&1 || true
    )"

    echo "$output" | grep -qi "successfully authenticated"
}

if check_github; then
    echo "[OK] GitHub autenticado via SSH."
else
    echo
    echo "[ATENÇÃO] Esta chave ainda não foi reconhecida pelo GitHub."
    echo
    echo "============================================================"
    echo " CHAVE SSH PÚBLICA"
    echo "============================================================"
    cat "$PUB_KEY"
    echo "============================================================"
    echo

    # No WSL, copia automaticamente para o clipboard do Windows.
    if command -v clip.exe >/dev/null 2>&1; then
        clip.exe < "$PUB_KEY"
        echo "[OK] Chave pública copiada para a área de transferência."
        echo
    fi

    echo "Adicione esta chave em:"
    echo "GitHub > Settings > SSH and GPG keys > New SSH key"
    echo
    echo "https://github.com/settings/keys"
    echo

    while true; do
        read -rp "Após cadastrar a chave, pressione ENTER para testar novamente ou [S] para sair: " ANSWER

        if [[ "${ANSWER,,}" == "s" ]]; then
            echo
            echo "[AVISO] Configuração SSH concluída, mas a autenticação GitHub"
            echo "        ainda precisa ser validada."
            break
        fi

        echo "==> Testando novamente..."

        if check_github; then
            echo "[OK] GitHub autenticado via SSH com sucesso!"
            break
        fi

        echo "[ERRO] O GitHub ainda não reconheceu esta chave."
        echo
    done
fi

echo
echo "=== [04] CONCLUÍDO ==="
echo
