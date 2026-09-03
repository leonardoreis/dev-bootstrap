#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [05] SHELL / ATALHO NTS ==="

NTS_GLOBAL_BIN="/usr/local/bin/nts"
BASHRC="$HOME/.bashrc"

# Criação do executável global nts em /usr/local/bin
sudo bash -c "cat > '$NTS_GLOBAL_BIN'" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/projects/nts-platform"

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "[ERRO] Repositório nts-platform não encontrado em: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

clear

cat <<'BANNER'
 _   _ _____ ____    ____  _        _  _____ _____ ___  ____  __  __
| \ | |_   _/ ___|  |  _ \| |      / \|_   _|  ___/ _ \|  _ \|  \/  |
|  \| | | | \___ \  | |_) | |     / _ \ | | | |_ | | | | |_) | |\/| |
| |\  | | |  ___) | |  __/| |___ / ___ \| | |  _|| |_| |  _ <| |  | |
|_| \_| |_| |____/  |_|   |_____/_/   \_\_| |_|   \___/|_| \_\_|  |_|
BANNER

echo
git status

if git diff --quiet && git diff --cached --quiet; then
    echo
    echo "Workspace limpo. Sincronizando com remote..."
    git pull --rebase || echo "[AVISO] Falha ao atualizar via git pull."
else
    echo
    echo "[INFO] Alterações locais detectadas. Sincronização ignorada."
fi

echo
if command -v code >/dev/null 2>&1; then
    echo "Abrindo o VS Code no diretório do projeto..."
    code .
else
    echo "[AVISO] VS Code (comando 'code') não encontrado no PATH."
fi
EOF

sudo chmod +x "$NTS_GLOBAL_BIN"

# Injeção no ~/.bashrc para sessões futuras
touch "$BASHRC"

sed -i \
    '/# >>> DEV-BOOTSTRAP PATH >>>/,/# <<< DEV-BOOTSTRAP PATH <<</d; /# >>> DEV-BOOTSTRAP SSH-AGENT >>>/,/# <<< DEV-BOOTSTRAP SSH-AGENT <<</d' \
    "$BASHRC"

cat >> "$BASHRC" <<'EOF'

# >>> DEV-BOOTSTRAP PATH >>>
if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
    export PATH="/usr/local/go/bin:$PATH"
fi
# <<< DEV-BOOTSTRAP PATH <<<

# >>> DEV-BOOTSTRAP SSH-AGENT >>>
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    if [ -S "$SSH_AUTH_SOCK" ]; then
        if ! ssh-add -l >/dev/null 2>&1; then
            rm -f "$SSH_AUTH_SOCK"
        fi
    fi

    if [ ! -S "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)" >/dev/null
    fi

    if ! ssh-add -l >/dev/null 2>&1; then
        ssh-add -t 8h "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    fi
fi
# <<< DEV-BOOTSTRAP SSH-AGENT <<<
EOF

echo "[OK] Atalho global 'nts' instalado em /usr/local/bin com sucesso."
