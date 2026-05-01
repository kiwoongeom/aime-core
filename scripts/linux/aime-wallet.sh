#!/bin/bash
# Aime wallet launcher (CLI)
#
# Auto-detects aime-wallet-cli and wallet file.
# Override with:
#   AIME_WALLET_CLI=/path/to/aime-wallet-cli
#   AIME_WALLET_FILE=/path/to/wallet
#   AIME_DAEMON_ADDR=host:port    (default 127.0.0.1:17081)

set -uo pipefail

find_wallet_cli() {
    if [ -n "${AIME_WALLET_CLI:-}" ] && [ -x "$AIME_WALLET_CLI" ]; then
        echo "$AIME_WALLET_CLI"
        return 0
    fi
    local candidates=(
        "$HOME/aime-core/build/Linux/aime-main/release/bin/aime-wallet-cli"
        "$HOME/aime-core/build/release/bin/aime-wallet-cli"
        "$HOME/aime-core/build/bin/aime-wallet-cli"
        "/usr/local/bin/aime-wallet-cli"
    )
    for c in "${candidates[@]}"; do
        [ -x "$c" ] && { echo "$c"; return 0; }
    done
    command -v aime-wallet-cli 2>/dev/null && return 0
    return 1
}

CLI="$(find_wallet_cli)" || {
    echo "ERROR: aime-wallet-cli not found. Set AIME_WALLET_CLI=/path/to/aime-wallet-cli or build aime-core." >&2
    exit 1
}

WALLET="${AIME_WALLET_FILE:-$HOME/aime-real}"
DAEMON="${AIME_DAEMON_ADDR:-127.0.0.1:17081}"

if [ ! -f "$WALLET.keys" ]; then
    echo "ERROR: wallet file not found at $WALLET" >&2
    echo "  Create one first:" >&2
    echo "    $CLI --offline --generate-new-wallet $WALLET" >&2
    exit 1
fi

exec "$CLI" --wallet-file "$WALLET" --daemon-address "$DAEMON" "$@"
