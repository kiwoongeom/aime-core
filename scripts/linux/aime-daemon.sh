#!/bin/bash
# Aime daemon launcher (P2P mode)
#
# Reads optional config:
#   ~/.aime/priority-peer.txt   — IP:PORT of priority peer (e.g. NAS, friend)
#   $AIME_PRIORITY_PEER         — overrides config file
#   --interactive               — passthrough flag for interactive shell
#
# Without priority peer, runs solo (P2P listening but no outbound peer).

set -uo pipefail

DAEMON_BIN="${AIME_DAEMON:-/root/aime/src/aime/build/Linux/aime-main/release/bin/aimed}"
DATA_DIR="${AIME_DATA_DIR:-/root/.aime}"

# Resolve priority peer
PRIORITY_PEER="${AIME_PRIORITY_PEER:-}"
if [ -z "$PRIORITY_PEER" ] && [ -f "$HOME/.aime/priority-peer.txt" ]; then
    PRIORITY_PEER=$(cat "$HOME/.aime/priority-peer.txt" | tr -d '[:space:]')
fi

# Build priority node arg
PEER_ARG=""
if [ -n "$PRIORITY_PEER" ]; then
    PEER_ARG="--add-priority-node $PRIORITY_PEER"
fi

# Interactive flag handling
NONINTERACTIVE="--non-interactive"
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--interactive" ]; then
        NONINTERACTIVE=""
    else
        ARGS+=("$arg")
    fi
done

if [ ! -x "$DAEMON_BIN" ]; then
    echo "ERROR: aimed binary not found at $DAEMON_BIN"
    echo "Build first: cd /path/to/aime-core && make release"
    exit 1
fi

echo "[INFO] Aime daemon starting (P2P mode)"
echo "[INFO] P2P listen:    0.0.0.0:17080"
echo "[INFO] RPC listen:    127.0.0.1:17081 (local only)"
echo "[INFO] Data dir:      $DATA_DIR"
if [ -n "$PRIORITY_PEER" ]; then
    echo "[INFO] Priority peer: $PRIORITY_PEER"
else
    echo "[INFO] Priority peer: none (solo mode)"
    echo "[INFO]   To set:      echo IP:17080 > ~/.aime/priority-peer.txt"
    echo "[INFO]   Or env var:  AIME_PRIORITY_PEER=IP:17080 $0"
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
    $PEER_ARG \
    $NONINTERACTIVE \
    "${ARGS[@]}"
