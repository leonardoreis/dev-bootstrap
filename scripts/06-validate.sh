#!/usr/bin/env bash
set -u

echo
echo "=== [06] VALIDAÇÃO DO AMBIENTE ==="
echo

FAILURES=0
WARNINGS=0

ok() {
    echo "[OK] $1"
}

fail() {
    echo "[FALHA] $1"
    FAILURES=$((FAILURES + 1))
}

warn() {
    echo "[AVISO] $1"
    WARNINGS=$((WARNINGS + 1))
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        ok "Ferramenta: $1"
    else
        fail "Ferramenta ausente: $1"
    fi
}

check_command git
check_command ssh
check_command curl
check_command go
check_command docker
check_command tree
check_command jq

echo

GIT_USER="$(git config --global user.name 2>/dev/null || true)"
if [ -n "$GIT_USER" ]; then
    ok "Git user.name: $GIT_USER"
else
    fail "Git user.name não configurado"
fi

GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [ -n "$GIT_EMAIL" ]; then
    ok "Git user.email: $GIT_EMAIL"
else
    fail "Git user.email não configurado"
fi

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    ok "Chave SSH privada encontrada"
else
    fail "Chave SSH privada não encontrada ($HOME/.ssh/id_ed25519)"
fi

if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    ok "Chave SSH pública encontrada"
else
    fail "Chave SSH pública não encontrada ($HOME/.ssh/id_ed25519.pub)"
fi

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

if [ -S "$SSH_AUTH_SOCK" ]; then
    ok "Socket do ssh-agent disponível"
else
    fail "Socket do ssh-agent não encontrado em $SSH_AUTH_SOCK"
fi

if ssh-add -l >/dev/null 2>&1; then
    ok "Chave SSH carregada na memória do agente"
else
    fail "Nenhuma chave ativa carregada no ssh-agent"
fi

SSH_RESULT="$(
    ssh -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -T git@github.com 2>&1 || true
)"

if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
    ok "Autenticação SSH no GitHub aceita"
else
    fail "Autenticação SSH no GitHub recusada"
fi

echo

if systemctl is-active --quiet docker 2>/dev/null || service docker status >/dev/null 2>&1; then
    ok "Serviço Docker daemon ativo"
else
    fail "Serviço Docker daemon inativo"
fi

if docker compose version >/dev/null 2>&1; then
    ok "Plugin Docker Compose operacional"
else
    fail "Plugin Docker Compose não disponível"
fi

if getent group docker 2>/dev/null | grep -qw "$USER"; then
    ok "Usuário '$USER' associado ao grupo 'docker'"
else
    fail "Usuário '$USER' NÃO pertence ao grupo 'docker'"
fi

if [ -x "$HOME/.local/bin/nts" ]; then
    ok "Executável nts instalado em ~/.local/bin/nts"
else
    fail "Executável nts não encontrado ou sem permissão de execução"
fi

if [ -d "$HOME/projects/nts-platform/.git" ]; then
    ok "Repositório nts-platform presente"

    NTS_REMOTE="$(git -C "$HOME/projects/nts-platform" remote get-url origin 2>/dev/null || true)"

    if [[ "$NTS_REMOTE" == git@github.com:* ]]; then
        ok "nts-platform usa SSH como origem remota"
    else
        warn "nts-platform não utiliza origem SSH: $NTS_REMOTE"
    fi
else
    fail "Repositório nts-platform não foi clonado"
fi

if [ -d "$HOME/projects/dev-bootstrap/.git" ]; then
    DEV_REMOTE="$(git -C "$HOME/projects/dev-bootstrap" remote get-url origin 2>/dev/null || true)"

    if [[ "$DEV_REMOTE" == git@github.com:* ]]; then
        ok "dev-bootstrap usa SSH como origem remota"
    else
        warn "dev-bootstrap não utiliza origem SSH: $DEV_REMOTE"
    fi
else
    fail "Repositório dev-bootstrap não encontrado"
fi

echo
echo "============================================================"
echo " Resultado Final da Validação"
echo "============================================================"
echo " Falhas : $FAILURES"
echo " Avisos : $WARNINGS"
echo

if [ "$FAILURES" -eq 0 ]; then
    echo "[OK] O ambiente atende a todos os requisitos de segurança e execução."
    exit 0
else
    echo "[FALHA] O ambiente possui dependências pendentes de ajuste."
    exit 1
fi
