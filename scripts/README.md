# Aime Helper Scripts

Convenience launchers for daemon, mining, and wallet on Linux and Windows (with WSL Ubuntu).

## Folder layout
```
scripts/
  linux/
    aime-daemon.sh       Daemon launcher (P2P mode)
    aime-wallet.sh       Wallet CLI launcher
  windows/
    aime-start.bat       Start daemon + mining + wallet (one click)
    aime-stop.bat        Stop everything
    aime-wallet.bat      Open wallet alone (daemon must be running)
```

## Prerequisites

1. **Build aime-core** (one-time):
   ```bash
   git clone --recursive https://github.com/kiwoongeom/aime-core.git ~/aime-core
   cd ~/aime-core
   make release
   ```
   This puts `aimed` and `aime-wallet-cli` in
   `~/aime-core/build/Linux/aime-main/release/bin/`.

2. **Get the miner package** (for mining):
   ```bash
   git clone https://github.com/kiwoongeom/aime-miner.git ~/aime-miner
   ```

3. **Set your wallet address** (for mining rewards):
   ```bash
   ~/aime-miner/aime-set-address.sh A...your-95-char-address...
   ```
   This saves to `~/.aime/last-wallet-address.txt`.

4. **Create a wallet** (one-time):
   ```bash
   ~/aime-core/build/Linux/aime-main/release/bin/aime-wallet-cli \
       --offline --generate-new-wallet ~/aime-real
   ```
   Write down the 25-word seed somewhere safe.

## Usage

### Linux
```bash
~/aime-core/scripts/linux/aime-daemon.sh   &   # in background
~/aime-core/scripts/linux/aime-wallet.sh        # interactive wallet
```

### Windows (with WSL Ubuntu)
- Double-click `aime-start.bat` — opens daemon, starts mining, opens wallet
- Double-click `aime-stop.bat` — stops everything
- Double-click `aime-wallet.bat` — opens wallet only

## Configuration (Linux env vars)

All scripts read these optional environment variables:

| Variable | Purpose | Default |
|---|---|---|
| `AIME_DAEMON` | Path to `aimed` binary | auto-detect in `~/aime-core/build/.../bin/aimed` |
| `AIME_WALLET_CLI` | Path to `aime-wallet-cli` | auto-detect |
| `AIME_WALLET_FILE` | Wallet file path | `~/aime-real` |
| `AIME_DATA_DIR` | Blockchain data dir | `~/.aime` |
| `AIME_PRIORITY_PEER` | LAN peer (e.g. `192.168.1.50:17080`) | none (uses hardcoded seed nodes) |
| `AIME_DAEMON_ADDR` | Wallet daemon endpoint | `127.0.0.1:17081` |

## Configuration (Windows files)

| File | Purpose |
|---|---|
| `%USERPROFILE%\.aime\last-wallet-address.txt` | Mining payout address (required) |
| `%USERPROFILE%\.aime\wallet-password.txt` | Wallet password for auto-login (optional) |

## Adjusting

- **Mining thread count**: edit `threads_count=4` in `aime-start.bat`
- **Different daemon location**: set `AIME_DAEMON` in WSL profile

## Security notes

- The wallet password file is plain text. For real-value wallets, do NOT save the password.
- The daemon RPC listens on `127.0.0.1:17081` (local only). Never expose RPC externally.
- The daemon P2P port `17080` listens on all interfaces. Restrict via firewall as needed.
