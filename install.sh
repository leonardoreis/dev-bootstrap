#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# PASSO 0: Correção Imediata de DNS (Garantia para Tailscale/VPN)
# Executado antes de qualquer tentativa de download/apt.
# ============================================================
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

echo "==> [1/3] Instalando dependências básicas (git, curl, ca-certificates)..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget

echo
echo "==> [2/3] Baixando a suíte de automação dev-bootstrap..."
mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    Repositório dev-bootstrap já existente. Sincronizando..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" reset --hard origin/main 2>/dev/null || git -C "$INSTALL_DIR" pull --rebase
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo
echo "==> [3/3] Configurando permissões dos scripts..."
chmod +x "$INSTALL_DIR/bootstrap-wsl.sh" 2>/dev/null || true
if [ -d "$INSTALL_DIR/scripts" ]; then
    find "$INSTALL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
fi

BOOTSTRAP_SCRIPT="$INSTALL_DIR/bootstrap-wsl.sh"

if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
    echo "[ERRO] Não foi possível localizar o arquivo $BOOTSTRAP_SCRIPT." >&2
    exit 1
fi

# Remove o arquivo install.sh temporário baixado no diretório atual
if [ -f "./install.sh" ] && [ "$(realpath ./install.sh)" != "$(realpath "$INSTALL_DIR/install.sh" 2>/dev/null)" ]; then
    rm -f ./install.sh
fi

echo
echo "==> Transferindo execução para a automação do WSL..."
echo

exec "$BOOTSTRAP_SCRIPT"
