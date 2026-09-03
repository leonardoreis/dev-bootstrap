#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [06] VALIDAÇÃO DO AMBIENTE ==="

check_cmd() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo " [OK] $cmd -> $(command -v "$cmd")"
    else
        echo " [FALHA] $cmd não encontrado" >&2
    fi
}

check_cmd "git"
check_cmd "curl"
check_cmd "go"
check_cmd "docker"

echo
if [ -d "$HOME/projects/nts-platform/.git" ]; then
    echo " [OK] Repositório nts-platform localizado."
else
    echo " [FALHA] Repositório nts-platform não localizado." >&2
fi

echo
echo "[OK] Validação concluída."
