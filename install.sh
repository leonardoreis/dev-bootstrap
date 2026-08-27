#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/leonardoreis/dev-bootstrap.git"
INSTALL_DIR="$HOME/projects/dev-bootstrap"

clear

echo "============================================================"
echo "          DEVELOPMENT WORKSTATION INSTALLER"
echo "============================================================"
echo

echo "==> Preparando instalação inicial..."

sudo apt update

sudo apt install -y \
    ca-certificates \
    curl \
    git

mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo
    echo "==> dev-bootstrap já existe."
    echo "==> Atualizando repositório..."

    git -C "$INSTALL_DIR" pull
else
    echo
    echo "==> Baixando dev-bootstrap..."

    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo
echo "==> Preparando scripts..."

chmod +x "$INSTALL_DIR/bootstrap-wsl.sh"
chmod +x "$INSTALL_DIR/scripts/"*.sh

echo
echo "==> Iniciando bootstrap..."
echo

exec "$INSTALL_DIR/bootstrap-wsl.sh"
