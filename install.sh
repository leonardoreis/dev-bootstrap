#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# PASSO 0: Correção Imediata de DNS (Garantia para Tailscale/VPN)
# ============================================================
echo "==> [Passo 0/4] Configurando DNS fixo para evitar travamentos..."

sudo bash -c 'cat <<EOF > /etc/wsl.conf
[boot]
systemd=true

[network]
generateResolvConf = false
EOF'

sudo rm -f /etc/resolv.conf
sudo bash -c 'cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
options timeout:2 attempts:2
EOF'

# ============================================================
# PASSO 1: Preparação do Ambiente e Dependências
# ============================================================
REPO_URL="https://github.com/leonardoreis/dev-bootstrap.git"
INSTALL_DIR="$HOME/projects/dev-bootstrap"

clear

echo "============================================================"
echo "          DEVELOPMENT WORKSTATION INSTALLER"
echo "============================================================"
echo

trap 'echo -e "\n[ERRO] A instalação foi interrompida na etapa anterior." >&2' ERR

echo "==> [Passo 1/4] Instalando dependências básicas (git, curl, wget)..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget

echo
echo "==> [Passo 2/4] Baixando a suíte de automação dev-bootstrap..."
mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    Repositório dev-bootstrap já existe. Sincronizando..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" reset --hard origin/main 2>/dev/null || git -C "$INSTALL_DIR" pull --rebase
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo
echo "==> [Passo 3/4] Aplicando permissões nos scripts..."
chmod +x "$INSTALL_DIR/bootstrap-wsl.sh" 2>/dev/null || true
if [ -d "$INSTALL_DIR/scripts" ]; then
    find "$INSTALL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
fi

BOOTSTRAP_SCRIPT="$INSTALL_DIR/bootstrap-wsl.sh"

if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
    echo "[ERRO] Não foi possível localizar o arquivo $BOOTSTRAP_SCRIPT." >&2
    exit 1
fi

# Remove o install.sh temporário caso tenha sido salvo no diretório atual
if [ -f "./install.sh" ] && [ "$(realpath ./install.sh)" != "$(realpath "$INSTALL_DIR/install.sh" 2>/dev/null)" ]; then
    rm -f ./install.sh
fi

echo
echo "==> [Passo 4/4] Transferindo execução para o bootstrap-wsl.sh..."
echo

exec "$BOOTSTRAP_SCRIPT"
