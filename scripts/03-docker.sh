#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [03] DOCKER ENGINE ==="

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "[OK] Docker e Docker Compose já instalados:"
    docker --version
    docker compose version
else
    echo "==> Configurando repositórios oficiais do Docker Engine..."

    sudo install -m 0755 -d /etc/apt/keyrings

    if [ -f /etc/apt/keyrings/docker.gpg ]; then
        sudo rm -f /etc/apt/keyrings/docker.gpg
    fi

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    ARCH="$(dpkg --print-architecture)"
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

    echo \
      "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

    echo "==> Instalando pacotes Docker..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

echo
echo "==> Ativando o serviço Docker via systemd..."
sudo systemctl enable --now docker 2>/dev/null || sudo service docker start || true

echo "==> Garantindo o grupo de usuários 'docker'..."
if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker
fi

echo "==> Adicionando o usuário '$USER' ao grupo 'docker'..."
sudo usermod -aG docker "$USER"

echo
echo "==> Verificando binários:"
docker --version
docker compose version

echo
echo "[OK] Docker Engine configurado."
echo "IMPORTANTE: Se foi a primeira adição ao grupo docker, pode ser necessário reiniciar o WSL para aplicar permissões sem sudo."
