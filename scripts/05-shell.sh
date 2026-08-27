#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [05] SHELL / COMANDO NTS ==="

NTS_DIR="$HOME/projects/nts-platform"
LOCAL_BIN="$HOME/.local/bin"
NTS_SCRIPT="$LOCAL_BIN/nts"
BASHRC="$HOME/.bashrc"

mkdir -p "$LOCAL_BIN"

cat > "$NTS_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/projects/nts-platform"

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo
    echo "[ERRO] Repositório nts-platform não encontrado em:"
    echo
    echo "  $PROJECT_DIR"
    echo
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
    echo "Workspace limpo. Atualizando..."

    if ! git pull; then
        echo
        echo "[AVISO] Não foi possível atualizar o repositório."
        echo "O ambiente local foi mantido sem alterações."
    fi
else
    echo
    echo "Há alterações locais. Git pull não executado."
fi

echo

if command -v code >/dev/null 2>&1; then
    code .
else
    echo "[AVISO] Comando 'code' não encontrado."
    echo "O projeto continuará aberto somente no terminal."
fi
EOF

chmod +x "$NTS_SCRIPT"

if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$BASHRC"; then
    echo >> "$BASHRC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

sed -i \
    '/# >>> DEV-BOOTSTRAP SSH-AGENT >>>/,/# <<< DEV-BOOTSTRAP SSH-AGENT <<</d' \
    "$BASHRC"

cat >> "$BASHRC" <<'EOF'

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
        ssh-add -t 8h "$HOME/.ssh/id_ed25519"
    fi
fi
# <<< DEV-BOOTSTRAP SSH-AGENT <<<
EOF

sed -i \
    '/# >>> DEV-BOOTSTRAP NTS >>>/,/# <<< DEV-BOOTSTRAP NTS <<</d' \
    "$BASHRC"

cat >> "$BASHRC" <<'EOF'

# >>> DEV-BOOTSTRAP NTS >>>
nts() {
    local project_dir="$HOME/projects/nts-platform"

    if [ ! -d "$project_dir/.git" ]; then
        echo
        echo "[ERRO] Repositório nts-platform não encontrado em:"
        echo
        echo "  $project_dir"
        echo
        return 1
    fi

    cd "$project_dir" || return 1
    "$HOME/.local/bin/nts"
}
# <<< DEV-BOOTSTRAP NTS <<<
EOF

echo
echo "[OK] ~/.local/bin configurado."
echo "[OK] ssh-agent configurado com validade de 8 horas."
echo "[OK] comando global 'nts' configurado."
echo
echo "A configuração será carregada automaticamente em novos terminais."