#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [05] SHELL / COMANDO NTS ==="

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/nts" <<'EOF'
#!/usr/bin/env bash
set -e

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
    git pull
else
    echo
    echo "Há alterações locais. Git pull não executado."
fi

echo

if command -v code >/dev/null 2>&1; then
    code .
else
    echo "VS Code não encontrado no ambiente WSL."
fi
EOF

chmod +x "$HOME/.local/bin/nts"

if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

sed -i \
    '/# >>> DEV-BOOTSTRAP NTS >>>/,/# <<< DEV-BOOTSTRAP NTS <<</d' \
    "$HOME/.bashrc"

cat >> "$HOME/.bashrc" <<'EOF'

# >>> DEV-BOOTSTRAP NTS >>>
nts() {
    cd "$HOME/projects/nts-platform" || return 1
    "$HOME/.local/bin/nts"
}
# <<< DEV-BOOTSTRAP NTS <<<
EOF

echo
echo "[OK] Comando nts configurado."