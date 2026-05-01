#!/bin/bash
# Aime daemon launcher (P2P mode)
#
# Auto-detects aimed binary in common locations.
# Override with: AIME_DAEMON=/path/to/aimed
#
# Optional config:
#   ~/.aime/priority-peer.txt   IP:PORT of LAN priority peer (e.g. NAS)
#   $AIME_PRIORITY_PEER         overrides config file
#   $AIME_DATA_DIR              defaults to ~/.aime
#
# Usage:
#   aime-daemon.sh                Run (non-interactive, exits on EOF)
#   aime-daemon.sh --interactive  Run in interactive shell mode

set -uo pipefail

# Locate aimed binary
find_daemon() {
    if [ -n "${AIME_DAEMON:-}" ] && [ -x "$AIME_DAEMON" ]; then
        echo "$AIME_DAEMON"
        return 0
    fi
    local candidates=(
        "$HOME/aime-core/build/Linux/aime-main/release/bin/aimed"
        "$HOME/aime-core/build/release/bin/aimed"
        "$HOME/aime-core/build/bin/aimed"
        "/usr/local/bin/aimed"
        "/usr/bin/aimed"
    )
    for c in "${candidates[@]}"; do
        if [ -x "$c" ]; then
            echo "$c"
            return 0
        fi
    done
    if command -v aimed >/dev/null 2>&1; then
        command -v aimed
        return 0
    fi
    return 1
}

DAEMON_BIN="$(find_daemon)" || {
    echo "ERROR: aimed binary not found." >&2
    echo "  Tried: \$AIME_DAEMON, ~/aime-core/build/..., /usr/local/bin/aimed, PATH" >&2
    echo "  Set AIME_DAEMON=/path/to/aimed or build aime-core first." >&2
    exit 1
}

DATA_DIR="${AIME_DATA_DIR:-$HOME/.aime}"
mkdir -p "$DATA_DIR"

# Resolve priority peer
PRIORITY_PEER="${AIME_PRIORITY_PEER:-}"
if [ -z "$PRIORITY_PEER" ] && [ -f "$HOME/.aime/priority-peer.txt" ]; then
    PRIORITY_PEER=$(head -1 "$HOME/.aime/priority-peer.txt" | tr -d '[:space:]')
fi

PEER_ARGS=()
if [ -n "$PRIORITY_PEER" ]; then
    PEER_ARGS+=("--add-priority-node" "$PRIORITY_PEER")
fi

# Interactive flag handling
NONINTERACTIVE_ARGS=("--non-interactive")
EXTRA_ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--interactive" ]; then
        NONINTERACTIVE_ARGS=()
    else
        EXTRA_ARGS+=("$arg")
    fi
done

echo "[INFO] Aime daemon"
echo "[INFO]   Binary:        $DAEMON_BIN"
echo "[INFO]   P2P listen:    0.0.0.0:17080"
echo "[INFO]   RPC listen:    127.0.0.1:17081 (local only)"
echo "[INFO]   Data dir:      $DATA_DIR"
if [ -n "$PRIORITY_PEER" ]; then
    echo "[INFO]   Priority peer: $PRIORITY_PEER"
else
    echo "[INFO]   Priority peer: (none, will use hardcoded seeds)"
fi
echo ""

exec "$DAEMON_BIN" \
    --p2p-bind-ip 0.0.0.0 \
    --p2p-bind-port 17080 \
    --rpc-bind-ip 127.0.0.1 \
    --rpc-bind-port 17081 \
    --confirm-external-bind \
    --no-igd \
    --data-dir "$DATA_DIR" \
    "${PEER_ARGS[@]}" \
    "${NONINTERACTIVE_ARGS[@]}" \
    "${EXTRA_ARGS[@]}"
