# Getting Started with Aime

> Step-by-step guide from zero to mining. Pick your scenario, then follow the steps.

---

## Pick your scenario

| What you want to do | Go to |
|---|---|
| **Mine AIME with your CPU** (most common) | [Scenario A](#scenario-a-mining) |
| **Run a network node** (validator, contributor) | [Scenario B](#scenario-b-running-a-node) |
| **Use a wallet** (send/receive, no mining) | [Scenario C](#scenario-c-wallet-only) |
| **Develop / build from source** | [Scenario D](#scenario-d-development) |

---

## Common prerequisites

### All scenarios need
- **Linux or WSL2 Ubuntu** (for daemon, wallet, miner core functionality)
- About **5 GB free disk** for source + builds
- About **2 GB RAM** minimum

### Windows users
You have two options:
- Use **WSL2 Ubuntu** for everything (recommended — same as Linux)
- Use **native Windows** for mining only (need separate XMRig.exe download)

> **Tip**: WSL2 is free, comes with Windows 10/11, and gives you a real Linux environment. Install via PowerShell as admin: `wsl --install -d Ubuntu`

---

## Scenario A: Mining

**Goal**: Mine AIME and earn block rewards to your wallet.

### A1. Get a wallet address (one-time, 2 minutes)

You need an AIME address to receive mining rewards. Three sub-options:

#### Option A1.a — Use the GUI wallet (easiest, Linux/WSL with desktop)
```bash
git clone https://github.com/kiwoongeom/aime-gui.git
cd aime-gui
sudo apt-get install -y qttools5-dev qttools5-dev-tools qtdeclarative5-dev libqt5svg5-dev \
  qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-dialogs \
  qml-module-qtquick2 qml-module-qtgraphicaleffects qml-module-qt-labs-settings \
  libgcrypt20-dev qml-module-qtquick-xmllistmodel qml-module-qtquick-shapes \
  qml-module-qtquick-templates2 qml-module-qtquick-window2
MANUAL_SUBMODULES=ON make
DISPLAY=:0 ./build/bin/monero-wallet-gui
```
GUI opens → "Create new wallet" → write down 25-word seed + address.

#### Option A1.b — Use the CLI wallet (lighter)
```bash
git clone https://github.com/kiwoongeom/aime-core.git
cd aime-core
sudo apt-get install -y build-essential cmake pkg-config ccache git \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev libsodium-dev \
  libunwind-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev \
  libpgm-dev libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler \
  libudev-dev libnorm-dev libgtest-dev
make release -j$(nproc)
./build/Linux/aime-main/release/bin/aime-wallet-cli --offline --generate-new-wallet mywallet
```
Follow prompts (password, mnemonic language) → write down address (starts with "A", 95 chars).

#### Option A1.c — Already have an address from someone
Just have the 95-char string ready (starts with "A").

### A2. Save your address for the miner (one-time)

Once you have your address, save it so the miner auto-uses it:

#### Linux / WSL
```bash
git clone https://github.com/kiwoongeom/aime-miner.git
cd aime-miner
./aime-set-address.sh AQWWPyLG4exW1...   # paste your full address
```

#### Windows (native)
```cmd
git clone https://github.com/kiwoongeom/aime-miner.git
cd aime-miner
aime-set-address.bat AQWWPyLG4exW1...
```

You'll see:
```
NEW: AQWWPyLG4exW1...
✓ Address saved to /home/USER/.aime/last-wallet-address.txt
```

### A3. Get a daemon (aimed) running

Mining needs a daemon to submit work to. Two options:

#### Option A3.a — Run your own daemon (most reliable)

If you built aime-core in step A1.b, you already have aimed. Otherwise:
```bash
git clone https://github.com/kiwoongeom/aime-core.git
cd aime-core
sudo apt-get install -y [build deps from A1.b]
make release -j$(nproc)
```

Then:
```bash
# Open a NEW terminal — daemon must keep running
./build/Linux/aime-main/release/bin/aimed --offline --no-igd
```

Wait for `core RPC server started ok on port: 17081`. Leave this terminal alone.

#### Option A3.b — Connect to someone else's daemon
If a friend or pool runs a public node, you can use their IP. Example:
```bash
./aime-mine.sh "" 4 friend.example.com:17081
```

### A4. Start mining

Open **another terminal** (the daemon must keep running). Then:

#### Linux / WSL
```bash
cd ~/aime-miner
./aime-mine.sh
```

#### Windows (native)
First download `xmrig.exe` from https://github.com/xmrig/xmrig/releases (file: `xmrig-X.X.X-msvc-win64.zip`). Extract and put `xmrig.exe` in the aime-miner folder. Then:
```cmd
cd aime-miner
aime-mine.bat
```

### A5. Watch it mine

You'll see:
```
[INFO] SOLO mode — mining via Aime daemon at 127.0.0.1:17081
[INFO] Address: AQWWPyLG4... (from ~/.aime/last-wallet-address.txt)
[INFO] Threads: 4
[INFO] Mining started inside aimed daemon.

[STATUS] height=1  diff=1  session_blocks=0  time=12:34:56
[12:34:58] +1 block(s) found! Total this session: 1
[STATUS] height=2  diff=8587  session_blocks=1  time=12:35:01
...
```

Each `+block found` = 17.59 AIME credited to your address (spendable after 60 confirmations).

### A6. Stop mining

- **Ctrl+C** in miner terminal → stops cleanly
- **Ctrl+C** in daemon terminal → stops daemon

You're done. Run again anytime with `./aime-mine.sh` (address auto-loaded).

---

## Scenario B: Running a node

**Goal**: Run a full node that validates the chain and serves data to others.

### B1. Build aime-core
Same as A1.b above.

### B2. Start daemon (foreground)
```bash
./build/Linux/aime-main/release/bin/aimed --p2p-bind-ip 0.0.0.0 --p2p-bind-port 17080 \
    --rpc-bind-ip 127.0.0.1 --rpc-bind-port 17081 --confirm-external-bind
```

### B3. (Optional) Open firewall port
```bash
sudo ufw allow 17080/tcp
```

### B4. (Optional) Run as systemd service for 24/7 uptime
See `RUN_NODE.md` in aime-core repo.

### B5. (Optional) Mine on your own node too
Follow Scenario A from step A4 onwards (your daemon is already running).

---

## Scenario C: Wallet only

**Goal**: Send/receive AIME without mining.

### C1. Get a wallet
Same as Scenario A1 (GUI or CLI option).

### C2. Connect to a node
- Your own (Scenario B)
- A public node (when available)

### C3. Use the wallet
- **Receive**: Share your address (95 chars, starts with "A")
- **Send**: `transfer <recipient_address> <amount>` in CLI, or use GUI's Send tab
- **Check balance**: `balance` command, or GUI's Account tab

---

## Scenario D: Development

**Goal**: Build all components from source, test locally.

### D1. Clone all repos
```bash
mkdir -p ~/aime-dev && cd ~/aime-dev
git clone https://github.com/kiwoongeom/aime-core.git
git clone https://github.com/kiwoongeom/aime-explorer.git
git clone https://github.com/kiwoongeom/aime-gui.git
git clone https://github.com/kiwoongeom/aime-miner.git
```

### D2. Build aime-core (daemon + wallets)
```bash
cd aime-core
make release -j$(nproc)
```

### D3. Build aime-explorer
```bash
cd ../aime-explorer
sudo apt-get install -y libasio-dev
mkdir build && cd build
cmake -DMONERO_DIR=$(realpath ../../aime-core) \
      -DMONERO_BUILD_DIR=$(realpath ../../aime-core/build/Linux/aime-main/release/) ..
make -j$(nproc)
```

### D4. Build aime-gui
```bash
cd ../../aime-gui
# Replace bundled monero/ with our aime-core
rsync -a --exclude='.git' --exclude='build' ../aime-core/ monero/
MANUAL_SUBMODULES=ON make
```

### D5. (Optional) Build XMRig
```bash
cd ../aime-miner
bash install_xmrig.sh
```

### D6. Run all components
- Terminal 1: `./aime-core/build/Linux/aime-main/release/bin/aimed --offline`
- Terminal 2: `cd aime-explorer/build && ./xmrblocks --port 8081 --bc-path ~/.aime/lmdb`
- Terminal 3: `DISPLAY=:0 ./aime-gui/build/bin/monero-wallet-gui`
- Terminal 4: `cd aime-miner && ./aime-mine.sh`

Browser → http://127.0.0.1:8081 for explorer.

---

## Common pitfalls

### "Permission denied" on /root/
```
bash: /root/aime/...: Permission denied
```
**Cause**: Files in /root/ require root access.
**Fix**: Use `sudo` or run `wsl -u root`.

### "No such file or directory" with .sh
```
-bash: ./aime-mine.sh: No such file or directory
```
**Cause**: You're not in the aime-miner directory.
**Fix**: `cd ~/aime-miner` first.

### "Cannot reach Aime daemon"
**Cause**: Daemon not running, or port mismatch.
**Fix**: Start aimed in another terminal first. Check `pgrep -a aimed`.

### Daemon crashes when terminal closes
**Cause**: Daemon was running in foreground without --detach.
**Fix**: Use `--detach --pidfile /tmp/aimed.pid` to run in background.

### PowerShell can't run .sh
**Cause**: Windows native CMD/PowerShell doesn't run bash scripts.
**Fix**: Either use WSL Ubuntu OR use the .bat version (`aime-mine.bat`).

### Korean comments in command examples
Don't paste comment text into the terminal. Only the code lines.

### Two-terminal pattern
Daemon and miner need their own terminals. Don't try to run both in one.

---

## Help

- Issues / bugs: file an issue on the relevant repo
- Build problems: see `INSTALL.md` in aime-core
- Mining specifics: see `HOW_TO_MINE.md` in aime-core
- Node operation: see `RUN_NODE.md` in aime-core
- API reference: see `API.md` in aime-core
- Security model: see `INHERITANCE_AND_REVIEW.md` in aime-core

## Project repos

| Repo | Purpose |
|---|---|
| https://github.com/kiwoongeom/aime-core | Daemon + CLI wallet + RPC wallet + docs |
| https://github.com/kiwoongeom/aime-explorer | Web block explorer |
| https://github.com/kiwoongeom/aime-gui | Qt GUI wallet |
| https://github.com/kiwoongeom/aime-miner | CPU miner package (XMRig wrapper) |

## License

BSD 3-Clause (inherited from Monero).

## Author

Kiwoong Eom — eric.eom@gmail.com — [@kiwoongeom](https://github.com/kiwoongeom)
