#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [03] DOCKER ENGINE ==="

if command -v docker >/dev/null 2>&1 &&
   docker compose version >/dev/null 2>&1; then
    echo "Docker já instalado:"
    docker --version
else
    echo "Instalando Docker Engine..."

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor --yes \
        -o /etc/apt/keyrings/docker.gpg

    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

echo
echo "==> Garantindo serviço Docker ativo..."

sudo systemctl enable --now docker

echo
echo "==> Garantindo grupo docker..."

if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker
fi

echo
echo "==> Adicionando usuário '$USER' ao grupo docker..."

sudo usermod -aG docker "$USER"

echo
echo "==> Versões instaladas..."

docker --version
docker compose version

echo
echo "[OK] Docker Engine instalado e configurado."

echo
echo "IMPORTANTE:"
echo "Se esta foi a primeira inclusão do usuário '$USER' no grupo docker,"
echo "feche e reabra o WSL após o bootstrap para aplicar a nova associação."