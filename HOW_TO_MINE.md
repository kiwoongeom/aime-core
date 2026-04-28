# How to Mine Aime (AIME)

> Aime uses RandomX, a CPU-friendly proof-of-work algorithm.
> Anyone with a modern CPU can mine effectively.

---

## Quick Start (Solo Mining)

### 1. Get the Aime daemon

```bash
git clone <aime-repo> aime
cd aime
make release -j$(nproc)
cd build/Linux/aime-main/release/bin
```

### 2. Create a wallet (you need an address to receive rewards)

```bash
./aime-wallet-cli --generate-new-wallet mywallet
# Choose password, language, write down the 25-word seed.
# Note your address — starts with "A" (e.g., AQWWPyLG4exW1QNg...)
```

### 3. Start mining

```bash
./aimed --start-mining <YOUR_AIME_ADDRESS> --mining-threads 2
```

That's it. The daemon will mine blocks and credit them to your address. Rewards become spendable after 60 confirmations (~2 hours).

---

## Recommended Setup (XMRig + Daemon)

XMRig is the standard, optimized RandomX miner. It's faster and more efficient than the daemon's built-in miner.

### 1. Run aimed in non-mining mode

```bash
./aimed --p2p-bind-port 17080 --rpc-bind-port 17081
```

### 2. Get XMRig

```bash
# Build from source (or download pre-built from xmrig.com)
git clone https://github.com/xmrig/xmrig
cd xmrig
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### 3. Configure XMRig for Aime

Create `xmrig.json`:

```json
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "threads": 2
    },
    "pools": [
        {
            "url": "127.0.0.1:17081",
            "user": "<YOUR_AIME_ADDRESS>",
            "pass": "x",
            "algo": "rx/0",
            "coin": "monero",
            "daemon": true
        }
    ],
    "log-file": "xmrig.log"
}
```

> **Note:** `coin: "monero"` and `algo: "rx/0"` because Aime uses identical RandomX algorithm. XMRig doesn't need to know "Aime" specifically — it just sees the same RandomX work.

### 4. Run XMRig

```bash
./xmrig --config=xmrig.json
```

---

## Mining Pool Setup (For Multiple Miners)

If you want multiple people to mine without each running a full node, set up a pool.

### Pool operator side

```bash
# Run aimed (full node)
./aimed --p2p-bind-port 17080 --rpc-bind-port 17081 --restricted-rpc

# Install P2Pool or NOMP, configure to point at aimed RPC
# Expose stratum port (e.g., :3333) publicly
```

### Miner side (anyone)

```bash
./xmrig -o pool.aime.network:3333 -u <YOUR_AIME_ADDRESS> -p worker1 --algo=rx/0
```

The pool distributes rewards proportionally to submitted shares.

---

## Hardware Performance (RandomX)

| CPU | Approx. hashrate |
|---|---|
| Intel i5 (4 cores) | ~2-3 KH/s |
| Intel i7 (8 cores) | ~5-8 KH/s |
| AMD Ryzen 5 5600 | ~6-8 KH/s |
| AMD Ryzen 9 7950X | ~25-30 KH/s |
| AMD Threadripper 3960X (24c/48t) | ~30-35 KH/s |
| RTX 4090 (GPU) | ~3-5 KH/s (CPU is more efficient!) |

> RandomX is intentionally inefficient on GPUs and infeasible on ASICs.
> A modern desktop CPU is ideal mining hardware.

---

## Memory Requirements

RandomX needs:
- **Light mode** (~256 MB RAM) — for verification only
- **Full mode** (~2 GB RAM) — for mining (much faster)

For mining, ensure huge pages are enabled:

```bash
# Linux
sudo sysctl -w vm.nr_hugepages=1280
echo "vm.nr_hugepages=1280" | sudo tee -a /etc/sysctl.conf
```

---

## Troubleshooting

### "BUSY" status when calling start_mining
- Aime patched this in Phase 9 — should not happen with current code.
- If it does, ensure you're using the latest aimed binary.

### "huge pages: 0 / 1280"
- Run as root or set `vm.nr_hugepages` (see above).
- Without huge pages, mining is ~10% slower but still works.

### Low hashrate
- Check CPU usage — should be near 100% on mining threads
- Increase `--mining-threads` (typically use cores, not all hyperthreads)
- Disable CPU power saving / set "performance" governor:
  ```bash
  sudo cpupower frequency-set -g performance
  ```

### Blocks not landing in wallet
- Wait 60 blocks (~2 hours) for confirmation
- Run `aime-wallet-cli refresh` to scan for new payments
- Check `show_transfers` for transaction history

---

## How Mining Rewards Are Calculated

Block reward formula (after v2 hard fork):
```
reward = max((MONEY_SUPPLY - already_generated) >> 19, 0.6 AIME)
```

- First mined block (height 1): ~17.59 AIME (v1, target 60s, esf=20)
- After v2 (target 120s, esf=19): ~35.18 AIME, decaying
- Tail emission (when reward < 0.6): permanent 0.6 AIME/block

Estimated annual emission:
- Year 1: ~5-10M AIME (rough, depends on hash distribution)
- Year 8+: ~157,000 AIME/year (tail only, approaching 0% inflation)

---

## Mining Etiquette

- **Don't hard 51%-attack a small chain** — even if technically possible, it destroys the project.
- **Run a full node if you can** — strengthens the network beyond just mining.
- **Disclose pool fees** — if running a pool, be transparent about fee %.
- **Use unique worker names** — helps you track which machine is contributing.

---

## Network Status

Check the live state:
- Daemon RPC: `curl http://127.0.0.1:17081/get_info`
- Block explorer: `http://explorer.aime.network` (when deployed)

Happy mining! 🎉
