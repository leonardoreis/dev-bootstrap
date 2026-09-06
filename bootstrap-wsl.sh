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


# ------------------------------------------------------------
# Executa scripts auxiliares
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# Preparação do ambiente
# ------------------------------------------------------------

run_script "01-base.sh"
run_script "04-git-ssh.sh"
run_script "02-go.sh"
run_script "03-docker.sh"


# ------------------------------------------------------------
# Garante Go disponível na sessão atual
# ------------------------------------------------------------

if [ -d "/usr/local/go/bin" ]; then
    export PATH="/usr/local/go/bin:$PATH"
fi


# ------------------------------------------------------------
# NTS Platform
# ------------------------------------------------------------

echo
echo "=== NTS PLATFORM ==="

SSH_AGENT_SOCKET="$HOME/.ssh/agent.sock"

if [ -S "$SSH_AGENT_SOCKET" ]; then
    export SSH_AUTH_SOCK="$SSH_AGENT_SOCKET"
fi

mkdir -p "$HOME/projects"


# ------------------------------------------------------------
# Sincronização segura do repositório NTS
# ------------------------------------------------------------

if [ -d "$NTS_DIR/.git" ]; then

    echo "[OK] Repositório nts-platform já existe."

    if [ -n "$(git -C "$NTS_DIR" status --porcelain)" ]; then

        echo
        echo "[INFO] Alterações locais detectadas em:"
        echo "       $NTS_DIR"
        echo
        echo "       A sincronização automática será ignorada"
        echo "       para preservar seu trabalho."

    else

        echo
        echo "==> Verificando atualizações em origin..."

        git -C "$NTS_DIR" fetch origin

        CURRENT_BRANCH="$(git -C "$NTS_DIR" branch --show-current)"

        if [ -z "$CURRENT_BRANCH" ]; then
            echo
            echo "[AVISO] O repositório está em estado detached HEAD."
            echo "        A sincronização automática foi ignorada."
        else
            echo "==> Sincronizando branch: $CURRENT_BRANCH"

            if git -C "$NTS_DIR" pull --ff-only; then
                echo "[OK] Repositório nts-platform atualizado."
            else
                echo
                echo "[AVISO] Não foi possível realizar fast-forward."
                echo "        O histórico local pode ter divergido do remoto."
                echo
                echo "        Nenhuma alteração local foi descartada."
                echo "        Resolva manualmente com Git antes de sincronizar."
            fi
        fi
    fi

else

    echo "==> Clonando nts-platform..."

    if ! git clone \
        git@github.com:leonardoreis/nts-platform.git \
        "$NTS_DIR"; then

        echo
        echo "[ERRO] Falha ao clonar o nts-platform." >&2
        echo "       Verifique a autenticação SSH com o GitHub." >&2
        echo
        echo "Teste sugerido:" >&2
        echo "  ssh -T git@github.com" >&2
        echo

        exit 1
    fi

    echo "[OK] nts-platform clonado com sucesso."
fi


# ------------------------------------------------------------
# Configuração de shell / atalhos
# ------------------------------------------------------------

run_script "05-shell.sh"


# ------------------------------------------------------------
# Validação do ambiente
# ------------------------------------------------------------

run_script "06-validate.sh"


# ------------------------------------------------------------
# Finalização
# ------------------------------------------------------------

echo
echo "============================================================"
echo "      INSTALAÇÃO CONCLUÍDA! INICIANDO O AMBIENTE NTS...     "
echo "============================================================"
echo

sleep 2

# Executa imediatamente o atalho global instalado.
exec /usr/local/bin/nts
