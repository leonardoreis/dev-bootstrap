#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [02] GO ==="

if command -v go >/dev/null 2>&1; then
    echo "[OK] Go já está instalado no sistema:"
    go version
else
    echo "==> Instalando Go via APT..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends golang-go

    echo
    if command -v go >/dev/null 2>&1; then
        go version
        echo "[OK] Go instalado com sucesso."
    else
        echo "[ERRO] Instalação do Go concluiu mas o executável não foi encontrado." >&2
        exit 1
    fi
fi
