#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [02] GO ==="

sudo apt update
sudo apt install -y golang-go

echo
go version

echo
echo "[OK] Go instalado."