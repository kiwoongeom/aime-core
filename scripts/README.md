# Aime Scripts — Daemon, Mining, Wallet

Convenience scripts for running Aime on Windows (with WSL Ubuntu).

## Folder layout
```
scripts/
├── linux/
│   └── aime-daemon.sh         # Daemon launcher (P2P mode)
└── windows/
    ├── aime-start.bat          # Start daemon + mining + wallet
    ├── aime-stop.bat           # Stop everything
    └── aime-wallet.bat         # Open wallet only (assumes daemon running)
```

## Prerequisites

1. **WSL Ubuntu 24.04** with `aimed` and `aime-wallet-cli` built
   - Default expected paths: `/root/aime/src/aime/build/Linux/aime-main/release/bin/`
   - Override with `AIME_DAEMON` environment variable
2. **Wallet created** at `/root/aime-real`
3. **Wallet address saved** at `%USERPROFILE%\.aime\last-wallet-address.txt`
   (Use `aime-set-address.bat` from aime-miner repo)
4. **(Optional) Wallet password** at `%USERPROFILE%\.aime\wallet-password.txt`
   for auto-login. Plain-text — only acceptable for low-stakes wallets.

## Configuration

### Address (required)
```cmd
echo Your-95-char-address > %USERPROFILE%\.aime\last-wallet-address.txt
```

### Wallet auto-login password (optional)
```cmd
echo your-password > %USERPROFILE%\.aime\wallet-password.txt
```

### Priority peer for daemon (optional, for connecting to a known seed/friend)
In WSL:
```bash
echo "192.168.1.50:17080" > ~/.aime/priority-peer.txt
```
Or environment variable:
```bash
export AIME_PRIORITY_PEER=192.168.1.50:17080
```

## Usage

### Start mining + wallet
Double-click `aime-start.bat`:
1. Cleans up old processes
2. Opens daemon window (foreground for log visibility)
3. Polls daemon RPC until ready (up to 60s)
4. Sends `start_mining` RPC to daemon (4 threads default)
5. Opens wallet window (auto-login if password file present)

### Stop everything
Double-click `aime-stop.bat`:
1. Closes wallet
2. Calls `stop_mining` RPC
3. Kills daemon

### Just open wallet
Double-click `aime-wallet.bat` (daemon must be running).

## Adjusting

- **Thread count for mining**: edit `threads_count=4` in `aime-start.bat` (line ~75)
- **Daemon flags**: edit `aime-daemon.sh` exec args
- **Different daemon binary path**: set `AIME_DAEMON` env var

## Security notes

- The wallet password file is plain text. For real-value wallets, do NOT save the password — let the wallet prompt instead.
- The daemon RPC listens on `127.0.0.1:17081` (local only). Never expose RPC externally.
- The daemon P2P port `17080` listens on all interfaces. Use a firewall to restrict if needed.
