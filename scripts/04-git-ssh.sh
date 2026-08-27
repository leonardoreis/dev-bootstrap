#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] GIT / SSH ==="

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo
    echo "Nenhuma chave SSH Ed25519 encontrada."
    echo "Criando uma nova chave para esta estação..."
    echo

    ssh-keygen \
        -t ed25519 \
        -f "$HOME/.ssh/id_ed25519"

    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
else
    echo
    echo "Chave SSH já existente."
fi

echo
echo "Chave pública desta estação:"
echo
cat "$HOME/.ssh/id_ed25519.pub"

echo
echo "------------------------------------------------------------"
echo "Se necessário, cadastre esta chave no GitHub:"
echo "Settings -> SSH and GPG keys -> New SSH key"
echo "------------------------------------------------------------"

echo
echo "[OK] Git/SSH preparado."