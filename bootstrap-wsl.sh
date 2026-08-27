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

"$ROOT_DIR/scripts/01-base.sh"

# Git/SSH vem cedo porque será necessário para acessar
# os repositórios privados.
"$ROOT_DIR/scripts/04-git-ssh.sh"

"$ROOT_DIR/scripts/02-go.sh"
"$ROOT_DIR/scripts/03-docker.sh"

# ------------------------------------------------------------
# NTS Platform
# ------------------------------------------------------------

echo
echo "=== NTS PLATFORM ==="

if [ -d "$NTS_DIR/.git" ]; then

    echo
    echo "[OK] Repositório nts-platform já existe."

else

    echo
    echo "==> Clonando nts-platform..."

    export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

    git clone \
        git@github.com:leonardoreis/nts-platform.git \
        "$NTS_DIR"

    echo
    echo "[OK] nts-platform clonado."

fi

"$ROOT_DIR/scripts/05-shell.sh"
"$ROOT_DIR/scripts/06-validate.sh"

echo
echo "============================================================"
echo " Bootstrap concluído."
echo "============================================================"
echo

echo "Ambiente preparado:"
echo
echo "  Git ............. OK"
echo "  SSH ............. OK"
echo "  Go .............. OK"
echo "  Docker .......... OK"
echo "  Docker Compose .. OK"
echo "  NTS Platform .... OK"
echo "  comando nts ..... OK"
echo

echo "IMPORTANTE:"
echo "Em novos terminais o comando 'nts' já estará disponível."
echo
echo "Iniciando NTS..."
echo

cd "$NTS_DIR"
"$HOME/.local/bin/nts"