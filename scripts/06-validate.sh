#!/usr/bin/env bash
set -u

echo
echo "=== [06] VALIDAÇÃO DO AMBIENTE ==="
echo

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "[OK] $1"
    else
        echo "[FALHA] $1"
    fi
}

check_command git
check_command curl
check_command go
check_command docker
check_command tree
check_command jq

echo

if systemctl is-active --quiet docker; then
    echo "[OK] Docker daemon ativo"
else
    echo "[FALHA] Docker daemon inativo"
fi

if docker compose version >/dev/null 2>&1; then
    echo "[OK] Docker Compose"
else
    echo "[FALHA] Docker Compose"
fi

if getent group docker | grep -qw "$USER"; then
    echo "[OK] Usuário '$USER' pertence ao grupo docker"
else
    echo "[FALHA] Usuário '$USER' não pertence ao grupo docker"
fi

if [ -x "$HOME/.local/bin/nts" ]; then
    echo "[OK] Script nts instalado"
else
    echo "[FALHA] Script nts não encontrado"
fi

if [ -d "$HOME/projects/nts-platform/.git" ]; then
    echo "[OK] Repositório nts-platform encontrado"
else
    echo "[PENDENTE] Repositório nts-platform ainda não clonado"
fi

echo
echo "=== VALIDAÇÃO CONCLUÍDA ==="