#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [01] BASE DO SISTEMA ==="

if ! systemctl is-system-running >/dev/null 2>&1; then
    echo "ERRO: systemd não está ativo."
    echo
    echo "Configure /etc/wsl.conf com:"
    echo
    echo "[boot]"
    echo "systemd=true"
    echo
    echo "Depois execute no PowerShell:"
    echo "wsl --shutdown"
    exit 1
fi

sudo apt update

sudo apt install -y \
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
    util-linux-extra

mkdir -p "$HOME/projects"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.ssh"

chmod 700 "$HOME/.ssh"

echo
echo "[OK] Base Linux preparada."