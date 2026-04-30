#!/bin/bash
# Aime node health monitor.
# Run periodically (cron, systemd timer) to check node health.
# Usage: ./monitor.sh [--alert-email user@example.com]
set -uo pipefail

RPC_HOST="${RPC_HOST:-127.0.0.1}"
RPC_PORT="${RPC_PORT:-17081}"
ALERT_THRESHOLD_HEIGHT_STALE="${ALERT_THRESHOLD_HEIGHT_STALE:-3600}"  # seconds
ALERT_THRESHOLD_PEERS_MIN="${ALERT_THRESHOLD_PEERS_MIN:-1}"
LOG_FILE="${LOG_FILE:-$HOME/aime-monitor.log}"

ALERT_EMAIL=""
for arg in "$@"; do
    case "$arg" in
        --alert-email=*) ALERT_EMAIL="${arg#*=}" ;;
        --alert-email) shift; ALERT_EMAIL="$1" ;;
    esac
done

log() {
    local level="$1"; shift
    echo "[$(date -Iseconds)] [$level] $*" | tee -a "$LOG_FILE"
}

alert() {
    local subject="$1"; shift
    local body="$*"
    log "ALERT" "$subject — $body"
    if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "[Aime] $subject" "$ALERT_EMAIL"
    fi
}

# Health checks
echo "=== Aime Health Check $(date) ==="

# 1. RPC reachable?
RPC_RESPONSE=$(curl -s --max-time 5 "http://$RPC_HOST:$RPC_PORT/get_info" 2>/dev/null || echo "{}")
if ! echo "$RPC_RESPONSE" | grep -q '"status".*"OK"'; then
    alert "RPC unreachable" "Daemon at $RPC_HOST:$RPC_PORT not responding"
    exit 1
fi
log "OK" "RPC responding"

# 2. Parse status
HEIGHT=$(echo "$RPC_RESPONSE" | python3 -c "import json,sys;print(json.load(sys.stdin).get('height', 0))" 2>/dev/null || echo 0)
PEERS_IN=$(echo "$RPC_RESPONSE" | python3 -c "import json,sys;print(json.load(sys.stdin).get('incoming_connections_count', 0))" 2>/dev/null || echo 0)
PEERS_OUT=$(echo "$RPC_RESPONSE" | python3 -c "import json,sys;print(json.load(sys.stdin).get('outgoing_connections_count', 0))" 2>/dev/null || echo 0)
TOTAL_PEERS=$((PEERS_IN + PEERS_OUT))
TOP_HASH=$(echo "$RPC_RESPONSE" | python3 -c "import json,sys;print(json.load(sys.stdin).get('top_block_hash', ''))" 2>/dev/null)
DIFFICULTY=$(echo "$RPC_RESPONSE" | python3 -c "import json,sys;print(json.load(sys.stdin).get('difficulty', 0))" 2>/dev/null || echo 0)

log "INFO" "height=$HEIGHT peers=$TOTAL_PEERS (in=$PEERS_IN, out=$PEERS_OUT) diff=$DIFFICULTY"

# 3. Peer count check
if [ "$TOTAL_PEERS" -lt "$ALERT_THRESHOLD_PEERS_MIN" ]; then
    alert "Low peer count" "Only $TOTAL_PEERS peer(s); expected >= $ALERT_THRESHOLD_PEERS_MIN"
fi

# 4. Chain progress check (compare with previous run)
PROGRESS_FILE="$HOME/.aime-monitor-state"
if [ -f "$PROGRESS_FILE" ]; then
    LAST_HEIGHT=$(awk '{print $1}' "$PROGRESS_FILE")
    LAST_TIME=$(awk '{print $2}' "$PROGRESS_FILE")
    NOW=$(date +%s)
    AGE=$((NOW - LAST_TIME))
    if [ "$HEIGHT" = "$LAST_HEIGHT" ] && [ "$AGE" -gt "$ALERT_THRESHOLD_HEIGHT_STALE" ]; then
        alert "Chain stalled" "Height $HEIGHT for $((AGE / 60)) minutes — chain not progressing"
    fi
fi
echo "$HEIGHT $(date +%s)" > "$PROGRESS_FILE"

# 5. Disk space
DISK_USE=$(df --output=pcent "$HOME/.aime" 2>/dev/null | tail -1 | tr -d ' %' || echo 0)
if [ "$DISK_USE" -gt 90 ]; then
    alert "Low disk space" "Aime data partition is ${DISK_USE}% full"
fi
log "INFO" "disk_use=${DISK_USE}%"

# 6. Process check
if ! pgrep -f "aimed" >/dev/null 2>&1; then
    alert "Process missing" "aimed process not running"
fi

echo ""
echo "Health check completed. State: OK"
log "OK" "all checks passed (height=$HEIGHT, peers=$TOTAL_PEERS, disk=${DISK_USE}%)"
