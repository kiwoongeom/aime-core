#!/bin/bash
# Check for Aime updates from the release server.
# Compares running version against latest release.
# Usage: ./check_for_updates.sh [release-url]
set -uo pipefail

RELEASE_URL="${1:-https://aime.network/releases/latest.json}"
AIMED="${AIMED:-aimed}"

if ! command -v "$AIMED" >/dev/null 2>&1; then
    echo "Aimed binary not found in PATH"
    exit 1
fi

# Get current version
CURRENT=$("$AIMED" --version 2>&1 | head -1 | grep -oP 'v\d+\.\d+\.\d+\.\d+' || echo "unknown")
echo "Current version: $CURRENT"

# Fetch latest version metadata
LATEST_JSON=$(curl -s --max-time 10 "$RELEASE_URL" 2>/dev/null || echo "{}")
if [ "$LATEST_JSON" = "{}" ]; then
    echo "Could not fetch update info from $RELEASE_URL"
    exit 1
fi

LATEST=$(echo "$LATEST_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin).get('version', 'unknown'))" 2>/dev/null)
LATEST_DATE=$(echo "$LATEST_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin).get('date', 'unknown'))" 2>/dev/null)
LATEST_NOTES=$(echo "$LATEST_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin).get('notes', ''))" 2>/dev/null)

echo "Latest version: $LATEST (released $LATEST_DATE)"

if [ "$CURRENT" = "$LATEST" ]; then
    echo "✓ You are up to date."
    exit 0
fi

echo ""
echo "⚠ Update available: $CURRENT → $LATEST"
[ -n "$LATEST_NOTES" ] && echo "Notes: $LATEST_NOTES"
echo ""
echo "To update:"
echo "  1. Download the latest binaries from https://aime.network/releases/"
echo "  2. Verify SHA256 hashes (see SHA256SUMS file)"
echo "  3. Verify GPG signature (see SHA256SUMS.asc)"
echo "  4. Replace existing binaries"
echo "  5. Restart aimed"
exit 2
