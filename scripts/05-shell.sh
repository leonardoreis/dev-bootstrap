#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [05] SHELL / COMANDO NTS ==="

LOCAL_BIN="$HOME/.local/bin"
NTS_SCRIPT="$LOCAL_BIN/nts"
BASHRC="$HOME/.bashrc"

mkdir -p "$LOCAL_BIN"

# Criação robusta do script nts
cat > "$NTS_SCRIPT" <<'EOF'
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
    if ! git pull --rebase; then
        echo "[AVISO] Falha ao atualizar via git pull. Mantendo cópia local intacta."
    fi
else
    echo
    echo "[INFO] Alterações locais detectadas. A atualização (git pull) foi ignorada."
fi

echo
if command -v code >/dev/null 2>&1; then
    code .
else
    echo "[AVISO] Comando 'code' (VS Code) não encontrado no PATH."
fi
EOF

chmod +x "$NTS_SCRIPT"

# Injeção idempotente no ~/.bashrc
touch "$BASHRC"

# Limpa blocos antigos do dev-bootstrap para evitar duplicatas
sed -i \
    '/# >>> DEV-BOOTSTRAP PATH >>>/,/# <<< DEV-BOOTSTRAP PATH <<</d; /# >>> DEV-BOOTSTRAP SSH-AGENT >>>/,/# <<< DEV-BOOTSTRAP SSH-AGENT <<</d; /# >>> DEV-BOOTSTRAP NTS >>>/,/# <<< DEV-BOOTSTRAP NTS <<</d' \
    "$BASHRC"

cat >> "$BASHRC" <<'EOF'

# >>> DEV-BOOTSTRAP PATH >>>
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
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

# >>> DEV-BOOTSTRAP NTS >>>
nts() {
    local project_dir="$HOME/projects/nts-platform"

    if [ ! -d "$project_dir/.git" ]; then
        echo "[ERRO] Repositório nts-platform não encontrado em: $project_dir" >&2
        return 1
    fi

    cd "$project_dir" || return 1
    "$HOME/.local/bin/nts"
}
# <<< DEV-BOOTSTRAP NTS <<<
EOF

echo
echo "[OK] ~/.local/bin adicionado ao PATH."
echo "[OK] Automação do ssh-agent atualizada no ~/.bashrc."
echo "[OK] Função global 'nts' registrada."
