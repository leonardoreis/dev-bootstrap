#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [02] GO LANGUAGE ==="

GO_VERSION="1.22.1"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"

if command -v go >/dev/null 2>&1; then
    CURRENT_GO_VER="$(go version | awk '{print $3}')"
    echo "[OK] Go já está instalado ($CURRENT_GO_VER)."
else
    echo "==> Baixando e instalando Go $GO_VERSION..."
    curl -fsSL "https://go.dev/dl/$GO_TAR" -o "/tmp/$GO_TAR"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/$GO_TAR"
    rm -f "/tmp/$GO_TAR"
    echo "[OK] Go instalado com sucesso."
fi
