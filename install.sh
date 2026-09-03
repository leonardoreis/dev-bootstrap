#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# DEVELOPMENT WORKSTATION INSTALLER
# ============================================================

REPO_URL="https://github.com/leonardoreis/dev-bootstrap.git"
INSTALL_DIR="$HOME/projects/dev-bootstrap"
BOOTSTRAP_SCRIPT="$INSTALL_DIR/bootstrap-wsl.sh"

DNS_FALLBACK_APPLIED=false

DNS_TEST_HOSTS=(
    "archive.ubuntu.com"
    "security.ubuntu.com"
    "download.docker.com"
    "go.dev"
    "github.com"
    "raw.githubusercontent.com"
)

HTTPS_TEST_URLS=(
    "https://archive.ubuntu.com"
    "https://security.ubuntu.com"
    "https://download.docker.com"
    "https://go.dev"
    "https://github.com"
    "https://raw.githubusercontent.com"
)

clear

cat <<'EOF'
============================================================
          DEVELOPMENT WORKSTATION INSTALLER
============================================================
EOF

echo
echo "Usuário : $USER"
echo "Host    : $(hostname)"
echo

trap 'echo -e "\n[ERRO] A instalação foi interrompida na etapa anterior." >&2' ERR


# ============================================================
# FUNÇÕES
# ============================================================

check_dns_host() {
    local host="$1"

    getent ahosts "$host" >/dev/null 2>&1
}


check_all_dns() {
    local host
    local failed=0

    echo
    echo "Verificando resolução DNS..."

    for host in "${DNS_TEST_HOSTS[@]}"; do
        printf "  %-32s " "$host"

        if check_dns_host "$host"; then
            echo "[OK]"
        else
            echo "[FALHA]"
            failed=1
        fi
    done

    return "$failed"
}


apply_dns_fallback() {
    echo
    echo "============================================================"
    echo " FALLBACK DNS"
    echo "============================================================"
    echo
    echo "[AVISO] Foram detectadas falhas de resolução DNS."
    echo "        Aplicando DNS alternativo para esta sessão WSL..."
    echo

    # Remove possível symlink/arquivo gerenciado pelo WSL.
    sudo rm -f /etc/resolv.conf

    sudo tee /etc/resolv.conf >/dev/null <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
options timeout:2 attempts:2
EOF

    sudo chmod 644 /etc/resolv.conf

    DNS_FALLBACK_APPLIED=true
}


check_https() {
    local url="$1"

    curl \
        --head \
        --silent \
        --show-error \
        --location \
        --fail \
        --connect-timeout 5 \
        --max-time 10 \
        "$url" \
        >/dev/null 2>&1
}


check_all_https() {
    local url
    local failed=0

    echo
    echo "Verificando conectividade HTTPS..."

    for url in "${HTTPS_TEST_URLS[@]}"; do
        printf "  %-40s " "$url"

        if check_https "$url"; then
            echo "[OK]"
        else
            echo "[FALHA]"
            failed=1
        fi
    done

    return "$failed"
}


# ============================================================
# PASSO 0/5: DIAGNÓSTICO DNS
# ============================================================

echo "==> [Passo 0/5] Verificando DNS..."

if ! command -v getent >/dev/null 2>&1; then
    echo
    echo "[AVISO] O comando 'getent' não está disponível."
    echo "        O diagnóstico DNS inicial será ignorado."
else
    if check_all_dns; then
        echo
        echo "[OK] DNS funcionando normalmente."
        echo "     Nenhuma alteração de DNS será realizada."
    else
        apply_dns_fallback

        echo
        echo "==> Testando DNS novamente..."

        if check_all_dns; then
            echo
            echo "[OK] Resolução DNS restaurada com o fallback."
        else
            echo
            echo "[ERRO] A resolução DNS continua apresentando falhas."
            echo
            echo "Possíveis causas:"
            echo "  - Tailscale/VPN"
            echo "  - firewall"
            echo "  - configuração de rede do WSL"
            echo "  - indisponibilidade externa"
            echo
            exit 1
        fi
    fi
fi


# ============================================================
# PASSO 1/5: DEPENDÊNCIAS BÁSICAS
# ============================================================

echo
echo "==> [Passo 1/5] Atualizando pacotes e instalando dependências..."

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget


# ============================================================
# PASSO 2/5: TESTE HTTPS
# ============================================================

echo
echo "==> [Passo 2/5] Verificando acesso HTTPS aos serviços necessários..."

if check_all_https; then
    echo
    echo "[OK] Serviços externos acessíveis via HTTPS."
else
    echo
    echo "[ERRO] O DNS está funcionando, mas um ou mais serviços"
    echo "       necessários não responderam via HTTPS."
    echo
    echo "Isso pode indicar:"
    echo "  - firewall"
    echo "  - proxy"
    echo "  - VPN/Tailscale"
    echo "  - bloqueio de rede"
    echo "  - indisponibilidade temporária do serviço"
    echo
    echo "Nenhuma nova alteração de DNS será realizada automaticamente."
    exit 1
fi


# ============================================================
# PASSO 3/5: DEV-BOOTSTRAP
# ============================================================

echo
echo "==> [Passo 3/5] Preparando suíte dev-bootstrap..."

mkdir -p "$HOME/projects"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    Repositório dev-bootstrap já existe."
    echo "    Verificando alterações locais..."

    if [ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]; then
        echo
        echo "[AVISO] Existem alterações locais em:"
        echo "        $INSTALL_DIR"
        echo
        echo "        A sincronização automática será ignorada"
        echo "        para evitar perda de trabalho."
    else
        echo "    Sincronizando com origin/main..."

        git -C "$INSTALL_DIR" fetch origin
        git -C "$INSTALL_DIR" pull --ff-only
    fi
else
    echo "    Clonando dev-bootstrap..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi


# ============================================================
# PASSO 4/5: PERMISSÕES
# ============================================================

echo
echo "==> [Passo 4/5] Aplicando permissões nos scripts..."

chmod +x "$BOOTSTRAP_SCRIPT" 2>/dev/null || true

if [ -d "$INSTALL_DIR/scripts" ]; then
    find "$INSTALL_DIR/scripts" \
        -type f \
        -name "*.sh" \
        -exec chmod +x {} +
fi


# ============================================================
# VALIDAÇÃO DO BOOTSTRAP
# ============================================================

if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
    echo
    echo "[ERRO] Não foi possível localizar:"
    echo "       $BOOTSTRAP_SCRIPT"
    exit 1
fi


# ============================================================
# LIMPEZA DO INSTALLER TEMPORÁRIO
# ============================================================

if [ -f "./install.sh" ]; then
    CURRENT_INSTALL="$(realpath ./install.sh 2>/dev/null || true)"
    REPO_INSTALL="$(realpath "$INSTALL_DIR/install.sh" 2>/dev/null || true)"

    if [ -n "$CURRENT_INSTALL" ] &&
       [ "$CURRENT_INSTALL" != "$REPO_INSTALL" ]; then

        rm -f ./install.sh
    fi
fi


# ============================================================
# PASSO 5/5: TRANSFERÊNCIA PARA O BOOTSTRAP
# ============================================================

echo
echo "==> [Passo 5/5] Transferindo execução para bootstrap-wsl.sh..."

if [ "$DNS_FALLBACK_APPLIED" = true ]; then
    echo
    echo "[INFO] Um fallback DNS foi necessário nesta sessão."
    echo "       Nenhuma configuração permanente do WSL foi alterada."
fi

echo

exec "$BOOTSTRAP_SCRIPT"
