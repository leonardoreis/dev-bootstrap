#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NTS_DIR="$HOME/projects/nts-platform"

clear

cat <<'EOF'
============================================================
              DEVELOPMENT WORKSTATION BOOTSTRAP
============================================================
EOF

echo
echo "Usuário : $USER"
echo "Host    : $(hostname)"
echo

trap 'echo -e "\n[ERRO] O bootstrap foi interrompido na etapa anterior." >&2' ERR

run_script() {
    local script_name="$1"
    local script_path="$ROOT_DIR/scripts/$script_name"
    
    if [ -f "$script_path" ]; then
        echo "------------------------------------------------------------"
        echo " Executando: $script_name"
        echo "------------------------------------------------------------"
        bash "$script_path"
    else
        echo "[ERRO] Script não encontrado: $script_path" >&2
        exit 1
    fi
}

run_script "01-base.sh"
run_script "04-git-ssh.sh"
run_script "02-go.sh"
run_script "03-docker.sh"

# ------------------------------------------------------------
# NTS Platform
# ------------------------------------------------------------

echo
echo "=== NTS PLATFORM ==="

# Garante o uso do socket SSH Agent caso esteja ativo
SSH_AGENT_SOCKET="$HOME/.ssh/agent.sock"
if [ -S "$SSH_AGENT_SOCKET" ]; then
    export SSH_AUTH_SOCK="$SSH_AGENT_SOCKET"
fi

mkdir -p "$HOME/projects"

if [ -d "$NTS_DIR/.git" ]; then
    echo "[OK] Repositório nts-platform já existente."
else
    echo "==> Clonando nts-platform..."
    if ! git clone git@github.com:leonardoreis/nts-platform.git "$NTS_DIR"; then
        echo "[ERRO] Falha ao clonar o nts-platform. Verifique as chaves SSH no GitHub." >&2
        exit 1
    fi
    echo "[OK] nts-platform clonado com sucesso."
fi

run_script "05-shell.sh"
run_script "06-validate.sh"

echo
echo "============================================================"
echo " Bootstrap concluído."
echo "============================================================"
echo

NTS_BIN="$HOME/.local/bin/nts"

if [ -x "$NTS_BIN" ]; then
    echo "Iniciando NTS Platform..."
    echo
    cd "$NTS_DIR"
    "$NTS_BIN"
else
    echo "[AVISO] O executável $NTS_BIN não foi encontrado."
    echo "Inicie manualmente com: nts"
fi
