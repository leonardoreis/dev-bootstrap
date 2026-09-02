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

echo "==> [Passo 1/3] Instalando dependências básicas no sistema limpo..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget

echo
echo "==> [Passo 2/3] Baixando a suíte de automação dev-bootstrap..."
mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    Repositório dev-bootstrap já existe. Atualizando..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" reset --hard origin/main 2>/dev/null || git -C "$INSTALL_DIR" pull --rebase
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo
echo "==> [Passo 3/3] Aplicando permissões nos scripts..."
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
echo "==> Tudo pronto. Transferindo execução para o bootstrap-wsl.sh..."
echo

# Remove o install.sh temporário baixado caso ele tenha sido salvo no diretório atual
if [ -f "./install.sh" ] && [ "$(realpath ./install.sh)" != "$(realpath "$INSTALL_DIR/install.sh" 2>/dev/null)" ]; then
    rm -f ./install.sh
fi

exec "$BOOTSTRAP_SCRIPT"
