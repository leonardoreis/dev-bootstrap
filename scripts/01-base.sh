#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [01] BASE DO SISTEMA ==="

# Validação do systemd no WSL
if ! systemctl is-system-running >/dev/null 2>&1; then
    # Checagem adicional: em boot frio do WSL, systemctl pode retornar "degraded"
    SYS_STATE="$(systemctl is-system-running 2>/dev/null || true)"
    if [ "$SYS_STATE" != "degraded" ] && [ "$SYS_STATE" != "running" ]; then
        echo "[ERRO] systemd não está ativo no ambiente WSL." >&2
        echo
        echo "Configure /etc/wsl.conf incluindo:"
        echo
        echo "[boot]"
        echo "systemd=true"
        echo
        echo "Depois reinicie o WSL no PowerShell com: wsl --shutdown"
        exit 1
    fi
fi

echo "==> Atualizando listas de pacotes..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

echo "==> Instalando pacotes base..."
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

# Criação de diretórios estruturais
mkdir -p "$HOME/projects"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.ssh"

chmod 700 "$HOME/.ssh"

echo
echo "[OK] Base Linux instalada e configurada com sucesso."
