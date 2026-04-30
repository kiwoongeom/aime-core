#!/bin/bash
# Generate SHA256 hashes + (optionally) PGP signatures for Aime release binaries.
# Usage: ./hash_release.sh [version-tag] [output-dir]
# Example: ./hash_release.sh v0.1.0 ./release
set -euo pipefail

VERSION="${1:-v0.1.0-dev}"
OUTPUT_DIR="${2:-./release}"

BIN_DIR="${BIN_DIR:-/root/aime/src/aime/build/Linux/aime-main/release/bin}"
GUI_BIN="${GUI_BIN:-/root/aime/src/monero-gui/build/bin/monero-wallet-gui}"
EXPLORER_BIN="${EXPLORER_BIN:-/root/aime/src/xmrblocks/build/xmrblocks}"

mkdir -p "$OUTPUT_DIR"

# Files to hash
declare -A FILES=(
    ["aimed-$VERSION-linux-x64"]="$BIN_DIR/aimed"
    ["aime-wallet-cli-$VERSION-linux-x64"]="$BIN_DIR/aime-wallet-cli"
    ["aime-wallet-rpc-$VERSION-linux-x64"]="$BIN_DIR/aime-wallet-rpc"
    ["aime-wallet-gui-$VERSION-linux-x64"]="$GUI_BIN"
    ["aime-explorer-$VERSION-linux-x64"]="$EXPLORER_BIN"
)

echo "================================================================"
echo "  Aime Release: $VERSION"
echo "  Date: $(date -Iseconds)"
echo "================================================================"

# Copy binaries with versioned names
for name in "${!FILES[@]}"; do
    src="${FILES[$name]}"
    if [ ! -f "$src" ]; then
        echo "  ⚠ Skipping: $src not found"
        continue
    fi
    cp "$src" "$OUTPUT_DIR/$name"
    chmod +x "$OUTPUT_DIR/$name"
done

# Generate SHA256SUMS file
echo "Computing SHA256 hashes..."
cd "$OUTPUT_DIR"
sha256sum aime* > SHA256SUMS 2>/dev/null
cat SHA256SUMS

echo ""

# Generate manifest with metadata
cat > MANIFEST.txt <<EOF
Aime Release Manifest
=====================
Version:     $VERSION
Build date:  $(date -Iseconds)
Build host:  $(hostname)
Builder:     $(whoami)
Platform:    $(uname -srm)

Files:
$(ls -la aime* 2>/dev/null | awk '{printf "  %-50s %s bytes\n", $NF, $5}')

SHA256 hashes: see SHA256SUMS
GPG signature: see SHA256SUMS.asc (if present)

To verify a download:
  sha256sum -c SHA256SUMS

To verify GPG signature (if present):
  gpg --verify SHA256SUMS.asc SHA256SUMS
EOF

echo "Manifest:"
cat MANIFEST.txt

# Try GPG sign if key available
if command -v gpg >/dev/null 2>&1; then
    if gpg --list-secret-keys 2>/dev/null | grep -q sec; then
        echo ""
        echo "Signing SHA256SUMS with GPG..."
        gpg --armor --detach-sign --output SHA256SUMS.asc SHA256SUMS
        echo "  ✓ Signed: SHA256SUMS.asc"
    else
        echo ""
        echo "  ℹ No GPG secret key found — skipping signature."
        echo "  To sign: generate a key with 'gpg --gen-key', then re-run."
    fi
fi

echo ""
echo "================================================================"
echo "  Release artifacts in: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
echo "================================================================"
