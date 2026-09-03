#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [03] DOCKER ENGINE ==="

if command -v docker >/dev/null 2>&1; then
    echo "[OK] Docker Engine já está instalado."
else
    echo "==> Configurando repositórios oficiais do Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

echo "==> Garantindo permissões do usuário no grupo Docker..."
sudo groupadd -f docker
sudo usermod -aG docker "$USER"

echo "[OK] Docker Engine configurado com sucesso."
