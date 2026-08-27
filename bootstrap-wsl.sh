#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
"$ROOT_DIR/scripts/02-go.sh"
"$ROOT_DIR/scripts/03-docker.sh"
"$ROOT_DIR/scripts/04-git-ssh.sh"
"$ROOT_DIR/scripts/05-shell.sh"
"$ROOT_DIR/scripts/06-validate.sh"

echo
echo "============================================================"
echo " Bootstrap concluído."
echo "============================================================"
echo
echo "Próximos passos:"
echo
echo "1. Cadastre a chave SSH pública no GitHub, se ainda não fez."
echo "2. Clone o projeto privado:"
echo
echo "   git clone git@github.com:leonardoreis/nts-platform.git ~/projects/nts-platform"
echo
echo "3. Feche e reabra o WSL para aplicar grupos e shell."
echo
echo "4. Depois use:"
echo
echo "   nts"