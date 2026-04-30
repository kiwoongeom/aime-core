#!/bin/bash
# Backup Aime wallet + (optionally) blockchain.
# Usage: ./backup.sh [--include-chain]
set -euo pipefail

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${BACKUP_DIR:-$HOME/aime-backups}"
DATA_DIR="${DATA_DIR:-$HOME/.aime}"
WALLET_PATTERN="${WALLET_PATTERN:-*}"

INCLUDE_CHAIN=false
if [ "${1:-}" = "--include-chain" ]; then
    INCLUDE_CHAIN=true
fi

mkdir -p "$BACKUP_DIR"

echo "==> Aime backup starting"
echo "    Date: $DATE"
echo "    Source: $DATA_DIR"
echo "    Destination: $BACKUP_DIR"

# 1. Wallet files (CRITICAL)
WALLETS=$(find "$DATA_DIR" -maxdepth 2 -name "*.keys" 2>/dev/null)
if [ -z "$WALLETS" ]; then
    echo "  No wallets found at $DATA_DIR"
else
    WALLET_TAR="$BACKUP_DIR/aime-wallets-$DATE.tar.gz"
    tar czf "$WALLET_TAR" -C "$DATA_DIR" \
        $(find "$DATA_DIR" -maxdepth 2 \( -name "*.keys" -o -name "*.address.txt" -o -name "*.cache" \) -printf "%P\n")
    chmod 600 "$WALLET_TAR"
    SIZE=$(du -h "$WALLET_TAR" | cut -f1)
    echo "  ✓ Wallets backed up: $WALLET_TAR ($SIZE)"
    echo "    SHA256: $(sha256sum "$WALLET_TAR" | cut -d' ' -f1)"
fi

# 2. Configuration
CONFIG_TAR="$BACKUP_DIR/aime-config-$DATE.tar.gz"
if [ -f "$DATA_DIR/aime.conf" ] || [ -d "$DATA_DIR/testnet" ] || [ -d "$DATA_DIR/stagenet" ]; then
    tar czf "$CONFIG_TAR" -C "$DATA_DIR" \
        $(find "$DATA_DIR" -maxdepth 1 \( -name "*.conf" -o -type d -name "testnet" -o -type d -name "stagenet" \) -printf "%P\n" 2>/dev/null) \
        2>/dev/null || true
    if [ -f "$CONFIG_TAR" ]; then
        SIZE=$(du -h "$CONFIG_TAR" | cut -f1)
        echo "  ✓ Config backed up: $CONFIG_TAR ($SIZE)"
    fi
fi

# 3. Blockchain (large, optional)
if [ "$INCLUDE_CHAIN" = true ] && [ -d "$DATA_DIR/lmdb" ]; then
    CHAIN_TAR="$BACKUP_DIR/aime-chain-$DATE.tar.gz"
    echo "  Backing up blockchain (this may take a while)..."
    tar czf "$CHAIN_TAR" -C "$DATA_DIR" lmdb
    SIZE=$(du -h "$CHAIN_TAR" | cut -f1)
    echo "  ✓ Blockchain backed up: $CHAIN_TAR ($SIZE)"
fi

# 4. Cleanup old backups (keep last 10 wallet backups)
ls -t "$BACKUP_DIR"/aime-wallets-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm
ls -t "$BACKUP_DIR"/aime-config-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm

echo ""
echo "==> Backup complete. Total backup size:"
du -sh "$BACKUP_DIR"

cat <<EOF

⚠️  CRITICAL REMINDERS:
   1. Wallet backups contain encrypted keys. Anyone with the password = your funds.
   2. Store your 25-word seed phrase OFFLINE, on paper. THIS IS THE ULTIMATE BACKUP.
   3. Test restore at least once. A backup never tested = no backup.

To restore wallet:
   tar xzf $BACKUP_DIR/aime-wallets-DATE.tar.gz -C $DATA_DIR
   aime-wallet-cli --wallet-file mywallet
EOF
