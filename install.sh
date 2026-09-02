#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/leonardoreis/dev-bootstrap.git"
INSTALL_DIR="$HOME/projects/dev-bootstrap"

clear

echo "============================================================"
echo "          DEVELOPMENT WORKSTATION INSTALLER"
echo "============================================================"
echo

trap 'echo -e "\n[ERRO] A instalação foi interrompida ou encontrou um erro." >&2' ERR

echo "==> Atualizando repositórios de pacotes..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

echo "==> Instalando dependências básicas..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git

mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "==> dev-bootstrap já instalado. Atualizando..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" reset --hard origin/main 2>/dev/null || git -C "$INSTALL_DIR" pull --rebase
else
    echo "==> Clonando dev-bootstrap..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo "==> Aplicando permissões de execução..."
chmod +x "$INSTALL_DIR/bootstrap-wsl.sh" 2>/dev/null || true
if [ -d "$INSTALL_DIR/scripts" ]; then
    find "$INSTALL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
fi

BOOTSTRAP_SCRIPT="$INSTALL_DIR/bootstrap-wsl.sh"

if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
    echo "[ERRO] Não foi possível localizar o script $BOOTSTRAP_SCRIPT." >&2
    exit 1
fi

echo
echo "==> Iniciando o bootstrap do WSL..."
echo

exec "$BOOTSTRAP_SCRIPT"
