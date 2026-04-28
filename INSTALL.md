# Aime Installation Guide

> Build and install Aime daemon, CLI wallet, and RPC wallet from source.
> For GUI wallet and block explorer, see their respective repos.

---

## Supported Platforms

| Platform | Status |
|---|---|
| Ubuntu 22.04+ | ✅ Tested |
| Ubuntu 24.04 | ✅ Tested |
| Debian 12 | ⚠ Should work, untested |
| Fedora 39+ | ⚠ Different package names — use equivalents |
| Arch Linux | ⚠ Should work — most deps in extra/ |
| macOS | ⚠ Use Homebrew, untested |
| Windows | 🔬 Use WSL2 + Ubuntu (recommended) |

---

## Prerequisites

### Ubuntu 22.04 / 24.04

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential cmake pkg-config ccache git wget curl ca-certificates \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev libsodium-dev \
  libunwind-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev \
  libpgm-dev libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler \
  libudev-dev libnorm-dev libgtest-dev
```

### Verify build tools

```bash
gcc --version    # Need >= 9
cmake --version  # Need >= 3.5
boost --version  # Need >= 1.58
```

### Hardware

- **Disk**: 5 GB minimum for source + build
- **RAM**: 2 GB minimum, 4+ GB recommended for parallel build
- **CPU**: x86_64, multi-core recommended (build scales linearly)

Build time on various CPUs:
- AMD Threadripper 3960X (48 threads): ~3-5 minutes
- Modern desktop (8 threads): ~15-30 minutes
- Older laptop (4 threads): ~30-60 minutes

---

## Build Aime daemon

### Clone

```bash
git clone <aime-core-repo> aime
cd aime
```

### Build

```bash
make release -j$(nproc)
```

This invokes the standard Monero-style Makefile, which:
1. Creates `build/Linux/aime-main/release/`
2. Runs CMake to configure
3. Compiles ~150,000 lines of C++ in parallel
4. Links static libraries into final binaries

### Output

Built binaries appear at:
```
build/Linux/aime-main/release/bin/
├── aimed                          (~16 MB)
├── aime-wallet-cli                (~17 MB)
├── aime-wallet-rpc                (~18 MB)
├── monero-blockchain-ancestry     (utility)
├── monero-blockchain-depth        (utility)
├── monero-blockchain-export       (utility)
├── monero-blockchain-import       (utility)
├── monero-blockchain-prune        (utility)
├── monero-blockchain-stats        (utility)
└── monero-blockchain-usage        (utility)
```

### Verify

```bash
./build/Linux/aime-main/release/bin/aimed --version
# Expected output: Aime 'Aime Genesis' (v0.18.4.6-...)
```

---

## Install (Optional)

To install system-wide:

```bash
sudo cp build/Linux/aime-main/release/bin/{aimed,aime-wallet-cli,aime-wallet-rpc} /usr/local/bin/
sudo chmod +x /usr/local/bin/aimed /usr/local/bin/aime-wallet-cli /usr/local/bin/aime-wallet-rpc
```

Now `aimed` etc. are available in PATH.

---

## First Run

### Start the daemon

```bash
aimed
# Daemon starts on default ports 17080/17081/17082
# It will create ~/.aime/ directory for blockchain data
```

### Create a wallet

In a separate terminal:

```bash
aime-wallet-cli --generate-new-wallet mywallet
# Choose password (twice)
# Choose mnemonic language (e.g., 0 for English)
# Write down 25-word seed safely!
# Note your address — starts with "A"
```

### Connect wallet to daemon

By default, wallet auto-connects to `127.0.0.1:17081`. To connect elsewhere:

```bash
aime-wallet-cli --daemon-address <NODE_IP>:17081 --wallet-file mywallet
```

---

## Troubleshooting

### "fatal error: boost/something.hpp: No such file"
Missing Boost dev headers. Install: `sudo apt-get install libboost-all-dev`

### "ld: cannot find -lXYZ"
Missing system library. The error message names which one — install corresponding `-dev` package.

### "FAILED: src/blockchain_db/lmdb/db_lmdb.cpp.o"
Out of memory during build. Reduce parallelism: `make release -j2`

### "Could not find Boost"
CMake can't auto-detect Boost. Set hint:
```bash
cmake -DBOOST_ROOT=/usr/include/boost ..
```

### Build succeeds but binary segfaults
Likely glibc mismatch. Make sure build host and run host have compatible glibc versions.

### Slow `make release` even though no source changes
ccache should help. Verify it's installed and working:
```bash
ccache --version  # Should be >= 4.0
ccache --show-stats  # See cache hit rates after a few builds
```

---

## Updating

### Pull latest source

```bash
git fetch
git pull
```

### Incremental rebuild

```bash
make release -j$(nproc)
```

ccache + Make will only recompile changed files. Typical update build: 1-3 minutes.

### Wallet/blockchain compatibility

- Wallet files: forward-compatible (older wallet works with newer daemon)
- Blockchain: usually forward-compatible with same major version (v0.18.x)
- Hard forks may require resync — check release notes

---

## Cross-Compilation (Advanced)

For deterministic / reproducible builds (recommended for releases):

See Monero's `contrib/depends/` documentation. Aime inherits the same toolchain.

```bash
# Build for Windows from Linux (example)
cd contrib/depends
make HOST=x86_64-w64-mingw32 -j$(nproc)
cd ../..
make depends target=x86_64-w64-mingw32 tag=v0.0.1-aime
```

---

## Companion Tools

- **Block Explorer**: `aime-explorer` (forked from xmrblocks)
  ```bash
  git clone <aime-explorer-repo>
  cd xmrblocks/build && cmake -DMONERO_DIR=../../aime ..
  make
  ```

- **GUI Wallet**: `aime-gui` (forked from monero-gui)
  ```bash
  git clone <aime-gui-repo>
  cd monero-gui && MANUAL_SUBMODULES=ON make
  ```

See respective READMEs in those repos for detailed instructions.

---

## Verifying Your Build

After build, verify by running the verification script:

```bash
bash notes/full_inventory.sh   # If you cloned with notes/
```

Or manually:

```bash
./build/Linux/aime-main/release/bin/aimed --version
./build/Linux/aime-main/release/bin/aime-wallet-cli --version

# Briefly run to check it boots cleanly:
timeout 3 ./build/Linux/aime-main/release/bin/aimed --offline --no-igd
# Should print initialization logs and exit at timeout
```

If versions print and daemon initializes without errors, build is good.

---

## Getting Help

- Check the project's GitHub Issues
- Review existing logs at `~/.aime/aime.log`
- Provide full daemon log + system info when reporting issues
