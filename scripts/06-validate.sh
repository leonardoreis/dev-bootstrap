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
        ok "$1"
    else
        fail "$1"
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

if [ -n "$(git config --global user.name 2>/dev/null)" ]; then
    ok "Git user.name: $(git config --global user.name)"
else
    fail "Git user.name não configurado"
fi

if [ -n "$(git config --global user.email 2>/dev/null)" ]; then
    ok "Git user.email: $(git config --global user.email)"
else
    fail "Git user.email não configurado"
fi

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    ok "Chave SSH privada encontrada"
else
    fail "Chave SSH privada não encontrada"
fi

if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    ok "Chave SSH pública encontrada"
else
    fail "Chave SSH pública não encontrada"
fi

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

if [ -S "$SSH_AUTH_SOCK" ]; then
    ok "Socket do ssh-agent disponível"
else
    fail "Socket do ssh-agent não encontrado"
fi

if ssh-add -l >/dev/null 2>&1; then
    ok "Chave carregada no ssh-agent"
else
    fail "Nenhuma chave carregada no ssh-agent"
fi

SSH_RESULT="$(
    ssh -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -T git@github.com 2>&1 || true
)"

if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
    ok "Autenticação SSH no GitHub"
else
    fail "Autenticação SSH no GitHub"
fi

echo

if systemctl is-active --quiet docker; then
    ok "Docker daemon ativo"
else
    fail "Docker daemon inativo"
fi

if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose"
else
    fail "Docker Compose"
fi

if getent group docker | grep -qw "$USER"; then
    ok "Usuário '$USER' configurado no grupo docker"
else
    fail "Usuário '$USER' não pertence ao grupo docker"
fi

if [ -x "$HOME/.local/bin/nts" ]; then
    ok "Comando nts instalado"
else
    fail "Comando nts não encontrado"
fi

if [ -d "$HOME/projects/nts-platform/.git" ]; then
    ok "Repositório nts-platform encontrado"

    NTS_REMOTE="$(
        git -C "$HOME/projects/nts-platform" remote get-url origin \
        2>/dev/null || true
    )"

    if [[ "$NTS_REMOTE" == git@github.com:* ]]; then
        ok "nts-platform usando remoto SSH"
    else
        warn "nts-platform não está usando remoto SSH: $NTS_REMOTE"
    fi
else
    fail "Repositório nts-platform não encontrado"
fi

if [ -d "$HOME/projects/dev-bootstrap/.git" ]; then
    DEV_REMOTE="$(
        git -C "$HOME/projects/dev-bootstrap" remote get-url origin \
        2>/dev/null || true
    )"

    if [[ "$DEV_REMOTE" == git@github.com:* ]]; then
        ok "dev-bootstrap usando remoto SSH"
    else
        warn "dev-bootstrap não está usando remoto SSH: $DEV_REMOTE"
    fi
else
    fail "Repositório dev-bootstrap não encontrado"
fi

echo
echo "============================================================"
echo " Resultado da validação"
echo "============================================================"
echo
echo " Falhas : $FAILURES"
echo " Avisos : $WARNINGS"
echo

if [ "$FAILURES" -eq 0 ]; then
    echo "[OK] Ambiente validado com sucesso."
    exit 0
else
    echo "[FALHA] O ambiente possui pendências."
    exit 1
fi