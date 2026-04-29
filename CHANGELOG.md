# Changelog — Aime

All notable changes to the Aime project.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v0.1.0-genesis] — 2026-04-29 (initial release)

First public release. All core functionality verified working.

### Added (vs Monero v0.18.4.6 baseline)
- **Custom chain identity**: New NETWORK_ID `1dd945d7-c142-4f38-87ce-42a20e325f10` for mainnet
- **Custom genesis block**: Hash `b78e36c0afe10470ec6dcc71c8ae8c1e4847d979aa788deb67dfa837bdcdfb29` with embedded message `"Aime 2026/04/27 - Genesis"`
- **Network ports**: 17080/17081/17082 (mainnet), 27080/27081/27082 (testnet), 37080/37081/37082 (stagenet) — non-conflicting with Monero
- **Address format**: First letter "A" via prefix byte 56
- **Branding**: All user-facing strings updated to "Aime"; data dir `~/.aime/`; config `aime.conf`; binaries `aimed`, `aime-wallet-cli`, `aime-wallet-rpc`
- **Tail emission**: Inherited from Monero (0.6 AIME/block forever after main emission ~18.13M)

### Changed
- `src/cryptonote_config.h`: All chain identifiers (NETWORK_ID, ports, address prefixes for 3 networks, GENESIS_TX, GENESIS_NONCE)
- `src/version.cpp.in`: Release name `Fluorine Fermi` → `Aime Genesis`
- `src/checkpoints/checkpoints.cpp`: Skipped Monero's hardcoded checkpoints (Aime is fresh chain)
- `src/rpc/core_rpc_server.cpp::check_core_ready()`: Always returns true (fresh chain has no upstream to sync against)
- `src/p2p/net_node.inl::get_ip_seed_nodes()`: Replaced Monero IPs with Aime placeholder comments
- 19 banner instances `"Monero '"` → `"Aime '"` across daemon/wallet/utility binaries
- 19 QML files: user-visible "Monero" text replaced with "Aime" (preserved namespace identifiers)

### Removed
- Monero's hardcoded checkpoint table (replaced with empty placeholder)
- Monero's hardcoded seed node IPs (replaced with Aime placeholder)

### Verified working
- ✓ All builds (daemon, CLI wallet, RPC wallet, GUI, explorer, miner)
- ✓ Genesis block parses correctly (RPC `get_block_header_by_height(0)` returns expected hash)
- ✓ RandomX mining produces real blocks (verified: blocks 1-5 mined with unique nonces)
- ✓ LWMA-2 difficulty adjustment (observed 1 → 8587 in 4 blocks)
- ✓ P2P sync between two local nodes (5-second handshake, identical top hash)
- ✓ Block explorer serves HTML (HTTP 200, 7569 bytes index)
- ✓ GUI launches under WSLg (Qt 5.15.13, 4K display detected)

### Companion releases
- aime-explorer v0.1.0-genesis (xmrblocks fork)
- aime-gui v0.1.0-genesis (monero-gui fork)
- aime-miner v0.1.0-genesis (XMRig wrapper package)

---

## Pre-release development log

For the development phase-by-phase timeline (Phases 1–16 of the project), see `notes/AIME_PROJECT.md` in the portfolio package.

Total development effort to v0.1.0-genesis: ~7.5 hours over 2 days.
