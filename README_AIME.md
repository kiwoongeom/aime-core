# Aime (AIME)

> Privacy-focused cryptocurrency forked from Monero v0.18, with custom chain identity.
> CPU-mineable via RandomX. Fully independent network.

**Created by:** Kiwoong Eom
**Email:** eric.eom@gmail.com
**GitHub:** [@kiwoongeom](https://github.com/kiwoongeom)
**Project started:** 2026-04-27

[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![Base](https://img.shields.io/badge/forked%20from-Monero%20v0.18.4.6-orange.svg)](https://github.com/monero-project/monero)
[![PoW](https://img.shields.io/badge/PoW-RandomX-purple.svg)](https://github.com/tevador/RandomX)

---

## What is Aime?

Aime is a learning-focused cryptocurrency project that forks the Monero codebase to create an independent privacy chain. It inherits Monero's strong privacy guarantees (ring signatures, RingCT, Bulletproofs+) while establishing its own network identity, address format, and genesis block.

**Key facts:**
- **Ticker:** AIME
- **Precision:** 1 AIME = 10¹² atomic units
- **Block time:** 120 seconds (LWMA-2 difficulty adjustment)
- **PoW:** RandomX (CPU-mineable, ASIC-resistant)
- **Privacy:** Mandatory — ring size 16, RingCT, Bulletproofs+
- **Emission:** Monero-orthodox tail emission (~18.13M main + 0.6 AIME/block forever)
- **Genesis hash:** `b78e36c0afe10470ec6dcc71c8ae8c1e4847d979aa788deb67dfa837bdcdfb29`
- **Address format:** Starts with `A` (e.g., `AQWWPyLG4exW1...`)

## Network parameters

| Network | P2P | RPC | ZMQ | Address prefix |
|---------|-----|-----|-----|----------------|
| Mainnet | 17080 | 17081 | 17082 | 56 |
| Testnet | 27080 | 27081 | 27082 | 87 |
| Stagenet | 37080 | 37081 | 37082 | 122 |

NETWORK_ID base: `1dd945d7-c142-4f38-87ce-42a20e325f__` (last byte: 10/11/12)

## Build

See [INSTALL.md](INSTALL.md) for full instructions.

```bash
# Ubuntu 22.04+
sudo apt-get install -y build-essential cmake pkg-config ccache git \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev libsodium-dev \
  libunwind-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev \
  libpgm-dev libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler \
  libudev-dev libnorm-dev libgtest-dev

git clone <this-repo> aime
cd aime
make release -j$(nproc)
# → ~3-5 min on modern multi-core CPU
# Output: build/Linux/aime-main/release/bin/{aimed, aime-wallet-cli, aime-wallet-rpc}
```

## Run a node

```bash
./aimed --p2p-bind-port 17080 --rpc-bind-port 17081
```

## Mine

See [HOW_TO_MINE.md](HOW_TO_MINE.md) for detailed mining setup.

```bash
./aimed --start-mining <YOUR_AIME_ADDRESS> --mining-threads 2
```

## Wallet

```bash
./aime-wallet-cli --generate-new-wallet mywallet
# Generates a 25-word seed and an address starting with "A"
```

## Companion projects

- **[aime-explorer](#)** — Web block explorer (forked from xmrblocks)
- **[aime-gui](#)** — Qt/QML graphical wallet (forked from monero-gui)

## Differences from Monero

| Aspect | Monero | Aime |
|---|---|---|
| NETWORK_ID | `1230f171-...-a110` | `1dd945d7-...-5f10` |
| P2P port | 18080 | 17080 |
| Address prefix | 18 (starts "4") | 56 (starts "A") |
| Genesis hash | `418015bb...` | `b78e36c0...` |
| Genesis message | (none) | "Aime 2026/04/27 - Genesis" |
| Daemon binary | monerod | aimed |
| Data directory | ~/.bitmonero/ | ~/.aime/ |

Two networks are fully isolated at protocol level (NETWORK_ID), OS level (ports), and visual level (addresses).

## Project status

This is currently a **learning/experimental project**, not a production cryptocurrency. The chain technically functions (verified via block production, P2P sync, mining, balance accounting), but has not been deployed to public infrastructure.

Roadmap toward production:
- [ ] Public seed nodes (VPS deployment)
- [ ] DNS seeds in code
- [ ] Block explorer hosting
- [ ] Domain + website
- [ ] Mining pool
- [ ] Wallet integration (Cake Wallet PR, etc.)

## Acknowledgments

Aime stands on the shoulders of:
- **The Monero Project** — for the foundational codebase and 12+ years of cryptographic research
- **Wownero** — as a reference for fork rebranding patterns
- **RandomX authors** (tevador et al.) — for the ASIC-resistant PoW
- **CryptoNote v2** — original protocol design

## License

BSD 3-Clause (inherited from Monero). See [LICENSE](LICENSE).

## Contributing

This is currently a single-developer learning project. Issues and PRs welcome but response time may vary.
