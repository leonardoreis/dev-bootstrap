#!/usr/bin/env bash
set -euo pipefail

echo
echo "=== [04] SSH & GIT IDEMPOTENTE ==="

SSH_KEY="$HOME/.ssh/id_ed25519"
PUB_KEY="$SSH_KEY.pub"

if [ -f "$SSH_KEY" ]; then
    echo "[OK] Chave SSH já existente em: $SSH_KEY"
else
    echo "==> Gerando chave SSH Ed25519..."
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$SSH_KEY" -N ""
    echo "[OK] Chave SSH gerada com sucesso."
fi

chmod 600 "$SSH_KEY"
chmod 644 "$PUB_KEY"

echo
echo "============================================================"
echo "   SUA CHAVE SSH PÚBLICA (Adicione ao GitHub se necessário):"
echo "============================================================"
cat "$PUB_KEY"
echo "============================================================"
echo
