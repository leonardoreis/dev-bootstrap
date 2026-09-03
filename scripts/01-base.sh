#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [01] BASE DO SISTEMA ==="

echo "==> Atualizando listas de pacotes apt..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

echo "==> Instalando ferramentas essenciais do sistema..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    make \
    gcc \
    build-essential \
    unzip \
    zip \
    jq \
    tree \
    util-linux-extra \
    openssh-client

mkdir -p "$HOME/projects"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

echo
echo "[OK] Base Linux instalada com sucesso."
