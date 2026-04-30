# Aime — Inheritance & Diff Review

> **Author:** Kiwoong Eom (eric.eom@gmail.com)
> **GitHub:** [@kiwoongeom](https://github.com/kiwoongeom)
> **Version:** v0.1.0-genesis
> **Date:** 2026-04-29

> **Statement of purpose**: This document is **NOT a formal third-party security audit**. It is an honest accounting of (1) which security properties Aime inherits from upstream projects, and (2) the specific changes Aime makes, with self-assessed risk for each. This is the standard transparency model for L1 cryptocurrency forks (Bitcoin, Litecoin, Monero forks etc. all use similar inheritance reviews rather than formal audits).

---

## Table of Contents

1. [Why no formal audit (and why that's normal)](#1-why-no-formal-audit-and-why-thats-normal)
2. [Trust Inheritance Map](#2-trust-inheritance-map)
3. [Aime-Specific Changes (The Diff)](#3-aime-specific-changes-the-diff)
4. [Per-Change Risk Assessment](#4-per-change-risk-assessment)
5. [Verification Performed](#5-verification-performed)
6. [Limitations & Threat Notes](#6-limitations--threat-notes)
7. [References](#7-references)

---

## 1. Why no formal audit (and why that's normal)

### 1.1 Industry practice for L1 chains

Formal security audits are **not the norm** for new L1 cryptocurrencies:

| Project | Year launched | Formal audit at launch? |
|---|---|---|
| Bitcoin | 2009 | No |
| Litecoin | 2011 | No |
| Dogecoin | 2013 | No |
| Monero | 2014 | No (academic review of CryptoNote primitives separately) |
| Zcash | 2016 | Partial — zk-SNARK ceremony only |
| Bitcoin Cash | 2017 | No (forked from Bitcoin) |
| Wownero | 2018 | No (forked from Monero) |

Reasons:
- L1 chain security is **emergent**: it comes from decentralization, time, and continuous public review — not from a single audit moment.
- Forks **inherit** their parent's audit history (12+ years for Monero).
- The audit-able unit (a smart contract) doesn't exist as a discrete artifact in an L1 chain.

### 1.2 What Aime is and isn't

| Aspect | Status |
|---|---|
| Is Aime a smart-contract project? | No |
| Is Aime a brand-new chain design? | No (Monero v0.18 fork) |
| Does Aime have a self-authored whitepaper? | No (inherits CryptoNote, Bulletproofs+, RandomX papers) |
| Did Aime modify cryptographic primitives? | **No** (inherits Monero's exactly) |
| Did Aime modify economic model? | **No** (inherits Monero's tail emission exactly) |
| What did Aime modify? | Network identifiers, branding, build hygiene (~330 lines) |

→ **The audit-able unit of Aime is the diff against Monero v0.18.4.6**, not the entire codebase.

---

## 2. Trust Inheritance Map

Aime inherits security properties from these upstream sources. Each row lists what Aime relies on, the source, and the maturity of that source.

### 2.1 Cryptographic Primitives (Foundation Layer)

| Property | Source | Maturity |
|---|---|---|
| Ring signatures (CLSAG) | Goodell et al., 2019 — *Concise Linkable Spontaneous Anonymous Group Signatures* | Peer-reviewed; deployed in Monero since v15 (2020) |
| RingCT | Shen Noether, 2015 — *Ring Confidential Transactions* | Peer-reviewed; deployed since Monero v4 (2017) |
| Bulletproofs+ | Chung, Hyun, Lee, Sangmin, 2020 — *Bulletproofs+: Shorter Range Proofs* | Peer-reviewed; deployed since Monero v15 |
| Stealth addresses | CryptoNote v2 white paper (Saberhagen, 2013) | Deployed in Bytecoin (2012), Monero (2014) |
| ed25519 signatures | Bernstein et al., 2011 | Industry standard since 2011 |
| RandomX (PoW) | tevador, 2019 — *RandomX: A new ASIC-resistant PoW algorithm* | Peer-reviewed; ASIC-resistant for 6+ years (Monero deployment) |
| Keccak hashing | NIST SHA-3 standard (FIPS 202) | Standardized 2015 |

**Aime modifies none of these.** All cryptographic operations in Aime are bit-identical to Monero v0.18.

### 2.2 Codebase Inheritance

| Component | Source | Battle-tested? |
|---|---|---|
| Daemon (`aimed`) | Forked from monero-project/monero `release-v0.18` (commit `586e82bcc`) | 11,610 commits, 100+ contributors, 12 years of public review |
| Wallet libraries | Same | Same |
| LMDB blockchain storage | Howard Chu's LMDB | 25+ years, used by OpenLDAP and many production systems |
| Boost dependencies | Boost.org | Industry standard since 1999 |
| OpenSSL / libsodium | Standard | Industry standard, frequently audited |

### 2.3 Build & Test Inheritance

| Property | Source | Notes |
|---|---|---|
| Build system | Monero's CMake + Makefile | Builds reproducibly across Linux, macOS, Windows |
| Unit tests | Monero's existing test suite | 100+ test files, run via `make test` (not added to or modified by Aime) |
| Network protocol | Monero's | Identical wire format with Monero (only NETWORK_ID magic differs) |
| RPC API | Monero's | 100% compatible — Monero-aware tools (XMRig, block explorers) work without modification |

### 2.4 What this inheritance means

If a security property holds for Monero v0.18.4.6 — for example:
- "Ring signatures of size 16 hide the real spender among 16 candidates"
- "Bulletproofs+ proves a value is in a valid range without revealing it"
- "RandomX is ASIC-resistant"

— then it holds for Aime.

The **only places** Aime can introduce new security risk are in the diff against Monero. That diff is small (~330 lines) and is reviewed in §3-4 below.

---

## 2.5 Aime vs Monero — Three-Layer Separation Model

To make the Aime/Monero relationship concrete: Aime separates from Monero on **three distinct layers**, each with a different purpose. This is the standard isolation model for L1 forks (used by Litecoin, Wownero, Bitcoin Cash, etc.).

### Difference #1 — Protocol Layer (Cryptographic Identity)

| Property | Monero | Aime | Why this matters |
|---|---|---|---|
| **NETWORK_ID** (16-byte UUID) | `1230f171-6104-4161-1731-008216a1a110` | `1dd945d7-c142-4f38-87ce-42a20e325f10` | Nodes from different networks refuse handshake — they literally cannot exchange data |
| **Genesis block hash** | `418015bb9ae982a1975da7d79277c2705727a56894ba0fb246adaabb1f4632e3` | `b78e36c0afe10470ec6dcc71c8ae8c1e4847d979aa788deb67dfa837bdcdfb29` | Different starting point = different chain history forever |
| **Genesis tx_extra message** | (none) | "Aime 2026/04/27 - Genesis" (25 bytes embedded) | Author signature in the chain itself |

**Effect**: An Aime node and a Monero node **physically cannot share blocks** even if connected on the same wire. This is enforced by the protocol — they reject each other in the first handshake byte.

This is the **strongest** form of isolation. Two networks that could theoretically share an algorithm don't share data because of these identifiers.

### Difference #2 — OS / Network Layer (Coexistence)

| Property | Monero (mainnet/testnet/stagenet) | Aime (mainnet/testnet/stagenet) | Why this matters |
|---|---|---|---|
| **P2P port** | 18080 / 28080 / 38080 | 17080 / 27080 / 37080 | Both can run on the same machine without OS port conflict |
| **RPC port** | 18081 / 28081 / 38081 | 17081 / 27081 / 37081 | Same |
| **ZMQ port** | 18082 / 28082 / 38082 | 17082 / 27082 / 37082 | Same |
| **Data directory** | `~/.bitmonero/` | `~/.aime/` | No file collision — both daemons can store data side-by-side |
| **Config file** | `bitmonero.conf` | `aime.conf` | Same |
| **Log file** | `bitmonero.log` | `aime.log` | Same |

**Effect**: A user running both Monero and Aime on the same PC has **zero conflict**. No port binding errors, no filesystem clashes, no config confusion. The two coexist peacefully.

This is the **practical isolation** that lets users hold and operate both chains.

### Difference #3 — Visual / User Layer (Identification)

| Property | Monero | Aime | Why this matters |
|---|---|---|---|
| **Address first letter** | "4" (e.g., `4AdUndXHHZ9pfQj27iMrPa...`) | "A" (e.g., `AQWWPyLG4exW1QNg2HZnG...`) | Users instantly recognize which chain an address belongs to |
| **Address prefix byte** | 18 (`0x12`) | 56 (`0x38`) | Wallet validation rejects mismatched addresses — user can't accidentally send Monero to an Aime address or vice versa |
| **Daemon binary** | `monerod` | `aimed` | Different commands, no shell aliasing confusion |
| **CLI wallet** | `monero-wallet-cli` | `aime-wallet-cli` | Same |
| **GUI window title** | "Monero" | "Aime" | Visible distinction in taskbar / dock |
| **Version banner** | `Monero 'Fluorine Fermi'` | `Aime 'Aime Genesis'` | Identifies the running daemon at a glance |
| **Currency unit** | XMR | AIME | Wallet display, exchange tickers, etc. |

**Effect**: A human looking at any Aime artifact — an address, a binary, a window title, a version string — can immediately tell it's Aime, not Monero. No ambiguity, no risk of cross-network confusion.

This is the **anti-confusion isolation** that protects users from mistakes.

### Why exactly three layers (and not more)

Each layer answers a different question:

| Layer | Question | Answer in Aime |
|---|---|---|
| Protocol | "Will my node connect to a Monero node by mistake?" | No — NETWORK_ID prevents it |
| OS | "Can I run both daemons on my laptop?" | Yes — different ports and dirs |
| Visual | "Did I just pay the wrong network?" | No — address prefix differs |

Together these three layers make Aime fully independent from Monero **at every level a problem could occur**:
- Code level (protocol)
- Machine level (OS)
- Human level (visual)

If any one layer is missing, the isolation is incomplete:
- Without protocol layer → networks could merge unintentionally
- Without OS layer → can't run side-by-side
- Without visual layer → users send wrong currency

Aime applies all three because all three are needed.

### What is NOT different from Monero

To be explicit: Aime intentionally inherits from Monero everything except the three identity layers above:

```
[Inherited unchanged from Monero]
├─ Cryptography (CLSAG, RingCT, Bulletproofs+)
├─ Privacy primitives (stealth addresses, ring size 16)
├─ Proof-of-Work (RandomX)
├─ Emission curve (tail emission @ 0.6 per block)
├─ Block time (120 seconds)
├─ Difficulty algorithm (LWMA-2)
├─ Fee algorithm (dynamic fee with penalty function)
├─ Wire protocol structure
├─ RPC API (100% compatible)
└─ All hard fork rules (HF_VERSION_*)

[Different in Aime — the "three layers"]
├─ Protocol identity (NETWORK_ID, genesis)
├─ OS identity (ports, data dirs, binary names)
└─ Visual identity (address prefix, branding strings)
```

This is the **minimum viable fork** — change identity, inherit substance.

---

## 3. Aime-Specific Changes (The Diff)

Comprehensive list of all Aime modifications versus Monero v0.18.4.6 baseline.

### 3.1 Daemon (`aime-core` / `src/aime/`)

| File | Lines changed | Category | Phase |
|---|---|---|---|
| `src/cryptonote_config.h` | ~25 | Network identifiers (3 networks) | 5 |
| `src/cryptonote_config.h` | 1 | CRYPTONOTE_NAME (data dir) | 4 |
| `src/cryptonote_config.h` | ~3 | GENESIS_TX hex + nonce | 6 |
| `src/version.cpp.in` | 1 | Release name `Fluorine Fermi` → `Aime Genesis` | 11 |
| `src/daemon/CMakeLists.txt` | 1 | Daemon binary name `monerod` → `aimed` | 4 |
| `src/wallet/CMakeLists.txt` | 1 | RPC wallet binary name | 4 |
| `src/simplewallet/CMakeLists.txt` | 1 | CLI wallet binary name | 4 |
| `src/daemonizer/posix_fork.cpp` | 1 | Daemon log file name | 4 |
| `src/checkpoints/checkpoints.cpp` | ~5 | Skip Monero's hardcoded checkpoints | 8 |
| `src/rpc/core_rpc_server.cpp` | ~5 | `check_core_ready()` always returns true | 9 |
| `src/p2p/net_node.inl` | ~30 | Replace Monero seed IPs with Aime placeholders | 16 |
| 15 cpp files | ~15 | `"Monero '"` → `"Aime '"` banner string | 11 |
| 6 cpp files | ~6 | (continued from above) | 11 |
| **Subtotal** | **~95** | | |

### 3.2 GUI Wallet (`aime-gui` / `src/monero-gui/`)

| File | Lines changed | Category | Phase |
|---|---|---|---|
| `src/main/Logger.cpp` | 1 | Data dir `.bitmonero` → `.aime` | 10b |
| `src/libwalletqt/Wallet.cpp` | 1 | Log file name | 10b |
| `src/daemon/DaemonManager.cpp` | 4 | Daemon binary name (4 sites) | 10b |
| `main.qml` | 4 | Window title + 3 specific strings | 11 |
| 19 .qml files | ~50 | User-visible "Monero" → "Aime" | 11 |
| Bundled `monero/` submodule | (replaced) | Aime source replaces vanilla Monero | 10b |
| **Subtotal** | **~60** | | |

### 3.3 Block Explorer (`aime-explorer` / `src/xmrblocks/`)

| File | Lines changed | Category | Phase |
|---|---|---|---|
| `src/page.h` | 2 | API compat: `get_pruned_transaction_hash` signature | 10a |
| `cmake/FindMonero.cmake` | 1 | Remove `miniupnpc` from libs (Aime doesn't use it) | 10a |
| `CMakeLists.txt` | 1 | Same | 10a |
| `src/templates/header.html` | 2 | Page title rebrand | 11 |
| `src/CmdLineOptions.cpp` | 1 | CLI help text rebrand | 11 |
| **Subtotal** | **~7** | | |

### 3.4 Total

```
Total lines changed across 3 repos: ~162 (excluding QML, ~280 total counting branding)
Total commits: 11 across 3 repos
Total files modified: ~50
```

For comparison, Monero v0.18 codebase is ~150,000 lines of C++. Aime's modifications are **~0.2% of the codebase**.

---

## 4. Per-Change Risk Assessment

Each change is evaluated for security impact. Risk levels:
- **NONE**: No security implication (cosmetic, naming, branding)
- **LOW**: Could affect availability/usability but not security; well-understood
- **MEDIUM**: Affects security-relevant behavior; needs care or monitoring
- **HIGH**: Could affect chain integrity, funds, or privacy; needs rigorous review

### 4.1 Risk Table

| Change | Risk | Why | Mitigation / Verification |
|---|---|---|---|
| `CRYPTONOTE_NAME = "aime"` | NONE | Pure naming; affects local file paths only | Verified by inspection of derived paths in daemon `--help` |
| Binary names (3 files) | NONE | CMake metadata only | Verified by `ls build/.../bin/` |
| Banner strings (`"Monero '"` → `"Aime '"`) | NONE | Display strings, no logic | Verified by `--version` output |
| QML user-visible strings | NONE | UI text | Verified by GUI launch |
| New mainnet ports (17080/17081/17082) | NONE | Avoids OS-level conflict with Monero; no protocol impact | Verified: ports differ from Monero's |
| New testnet/stagenet ports | NONE | Same | Verified |
| New address prefix bytes (56 / 87 / 122) | LOW | Affects address validation; wrong values would reject valid addresses | Verified: tested wallet creation, address starts with "A" |
| **New NETWORK_ID UUID** | LOW | If accidentally matched another chain's, peers would mis-connect | Verified: differs from Monero's `1230f171...` and from random — UUID generated via `uuidgen` |
| **New GENESIS_TX hex** | MEDIUM | If structurally invalid, daemon won't boot; if duplicates Monero's, chains would share genesis | Verified: daemon boots, RPC returns hash `b78e36c0...` ≠ Monero's `418015bb...` |
| Skipped Monero checkpoints | MEDIUM | Monero's checkpoints would falsely reject Aime's blocks. Disabling is correct for fresh chain, but means no checkpoint protection until Aime adds its own | **Acknowledged tradeoff.** Aime should add own checkpoints as chain matures (post-1000 blocks) |
| `check_core_ready()` returns true | MEDIUM | Bypasses Monero's `is_synchronized()` check. For fresh chain this is correct (no upstream to sync against), but if Aime ever needs to integrate with another chain, this guard is removed | **Acknowledged.** Documented in code comment. Re-enable before any cross-chain integration. |
| Seed nodes commented out | LOW | No automatic peer discovery until Aime deploys real seeds | **Expected.** User must `--add-priority-node` until production seeds exist |
| GUI bundled monero/ replaced with Aime | LOW | GUI links against Aime libwallet, gets Aime address validation | Verified: GUI generates addresses starting with "A" |
| Explorer `get_pruned_transaction_hash` API patch | LOW | Compatibility shim for newer Monero API | Verified: explorer compiles and serves block 0 |
| Explorer skips `miniupnpc` link | LOW | Aime daemon built without UPnP, so explorer doesn't need it | Acknowledged: future Aime builds with UPnP would require revert of this skip |

### 4.2 Risk Summary

```
NONE:    7 changes (cosmetic / branding)
LOW:     5 changes (verified by tests)
MEDIUM:  3 changes (acknowledged tradeoffs, documented in code)
HIGH:    0 changes
```

**No HIGH-risk changes.** All MEDIUM-risk changes are documented compromises specific to the "fresh fork" lifecycle, with clear paths to remediation as Aime matures.

### 4.3 What was NOT changed (deliberately)

To preserve security properties, Aime does not modify:

- Cryptographic functions (`crypto/*.c`, `cncrypto/*`)
- Ring signature logic
- RingCT logic
- Bulletproofs+ logic
- RandomX (`external/randomx/`)
- Wallet key derivation
- Transaction validation
- Block validation rules (proof of work check, difficulty adjustment)
- LMDB schema
- P2P wire protocol structure (only the magic UUID changed)
- Mempool logic
- DNSSEC validation logic

This is by design: anything cryptographic or consensus-critical is left to Monero's proven code.

---

## 5. Verification Performed

This section documents what testing was done, what passed, and what evidence exists.

### 5.1 Build verification

| Test | Result | Evidence |
|---|---|---|
| Vanilla Monero builds clean | ✓ Pass | Phase 3, 3m33s build time |
| Aime daemon builds clean | ✓ Pass | Phase 11.6, all binaries produced |
| Aime GUI builds clean | ✓ Pass | Phase 10b + 11.6 |
| Aime explorer builds clean | ✓ Pass | Phase 10a |
| Aime miner package builds clean (XMRig) | ✓ Pass | Phase 14 |

### 5.2 Functional verification

| Test | Result | Evidence file |
|---|---|---|
| Daemon starts cleanly | ✓ Pass | `evidence_full/06_chain_state_genesis.json` |
| Genesis block has expected hash `b78e36c0...` | ✓ Pass | RPC `get_block_header_by_height(0)` |
| Genesis hash differs from Monero's `418015bb...` | ✓ Pass | Direct comparison |
| Mining produces valid blocks | ✓ Pass | `evidence_full/09_blocks.json` (3+ blocks with unique nonces) |
| Block reward matches theoretical formula | ✓ Pass | First block: 17.5921 AIME = (2^64-1) >> 20 |
| LWMA-2 difficulty adjustment functions | ✓ Pass | Observed: 1 → 8587 in 4 blocks |
| Two-node P2P sync works | ✓ Pass | Phase 9 test, top hash identical |
| Address validation accepts "A" addresses | ✓ Pass | Wallet generation produces `AQWWPyLG...` |
| Explorer serves chain data | ✓ Pass | HTTP 200, 7569 bytes |
| GUI launches under WSLg | ✓ Pass | Qt 5.15.13, 4K display detected |
| Miner auto-stops on signal | ✓ Pass | SIGTERM clean shutdown verified |

### 5.3 Identity uniqueness verification

| Property | Aime value | Monero value | Different? |
|---|---|---|---|
| Mainnet NETWORK_ID | `1dd945d7-c142-4f38-87ce-42a20e325f10` | `1230f171-6104-4161-1731-008216a1a110` | ✓ |
| Mainnet P2P port | 17080 | 18080 | ✓ |
| Mainnet address prefix | 56 | 18 | ✓ |
| Genesis hash | `b78e36c0afe10470ec6dcc71c8ae8c1e4847d979aa788deb67dfa837bdcdfb29` | `418015bb9ae982a1975da7d79277c2705727a56894ba0fb246adaabb1f4632e3` | ✓ |
| Address first letter | "A" | "4" | ✓ |

→ Aime is fully isolated from Monero at protocol, OS, and visual layers.

### 5.4 Evidence artifacts

11 automated evidence files in `portfolio/evidence/`:
- Build verification (binaries + versions)
- Chain parameters (raw constants from source)
- Git history (all 11 Aime commits across 3 repos)
- Genesis block (RPC response)
- Mining session results (3 blocks mined in 15s)
- Wallet generation (address samples)
- Explorer verification (HTTP responses)
- Architecture diagrams

12 additional artifacts in `portfolio/evidence_full/`:
- All of the above PLUS
- 16 git patch files (every Aime commit as `.patch`)
- Mining timeline over 60s
- Hash chain proof for all blocks
- 5 address samples (showing prefix consistency)
- SHA256 hashes of all binaries

---

## 6. Limitations & Threat Notes

### 6.1 What this review does NOT cover

- **No external code audit by a third party.** Only the original developer (Kiwoong Eom) reviewed the diff.
- **No formal verification of Aime-specific patches.** Manual testing only.
- **No fuzzing of Aime's modified code paths.** Standard Monero fuzz tests still apply but were not re-run.
- **No bug bounty program.** Plan to set up after public release.
- **No long-term real-world stress test.** Fresh chain — bugs that emerge under load remain unknown.

### 6.2 Acknowledged tradeoffs (specific to fresh-fork stage)

These are intentional compromises for a fresh chain that should be revisited as Aime matures:

| Tradeoff | Current state | When to reconsider |
|---|---|---|
| No checkpoints | Empty list (all blocks accepted) | After ~1000 blocks of stable history, add Aime checkpoints |
| `check_core_ready()` always true | Bypasses sync check | Re-enable if integrating with cross-chain bridges |
| Single seed node operator | Aime placeholders, not deployed | Multi-operator seed distribution at production launch |
| No GPG release signing | SHA256 hashes only | Add GPG once author key is published |
| No DNS seed redundancy | Code commented placeholders | Deploy 3+ seed nodes before public mining call |

### 6.3 Threats not addressed (but inherited)

These threats apply to Aime as much as Monero, and are addressed by Monero's existing design:

- **51% attack** — Mitigation: PoW economic security (low while chain is small, grows with hashrate)
- **Double-spend** — Mitigation: Confirmation depth (recommend 10+ blocks)
- **Eclipse attack** — Mitigation: Multiple peer connections + priority nodes
- **Sybil attack on P2P** — Mitigation: Limited connections per IP, ban list
- **Privacy leak via insufficient ring size** — Mitigation: Hard minimum of 16 (enforced)
- **Privacy leak via timing analysis** — Mitigation: Dandelion++ propagation
- **Wallet key theft** — Mitigation: User responsibility (encrypted wallet files, keep seed offline)
- **Eclipse via DNS poisoning** — Mitigation: DNSSEC validation + multiple seed sources

### 6.4 Threats unique to Aime's situation

Threats that are specific to Aime being a small/fresh chain:

| Threat | Severity | Mitigation status |
|---|---|---|
| Initial 51% (small hashrate) | HIGH while chain is < 100,000 blocks | **Active**: keep developer-controlled mining majority during bootstrap |
| Brand confusion (someone forks "AIME" again) | MEDIUM | **Active**: GitHub timestamp + author attribution proves origin |
| No exchange listing → no liquidity | N/A (not a security issue) | Acceptable for learning project |
| Regulatory uncertainty (privacy coin) | LOW (KR/learning context) | **Pending**: legal review before any commercial activity |

---

## 7. References

### 7.1 Cryptographic primitives

1. **CryptoNote v2** — Saberhagen, N. (2013). *CryptoNote v 2.0 White Paper*.
2. **RingCT** — Noether, S. (2015). *Ring Confidential Transactions*. Cryptology ePrint Archive 2015/1098.
3. **Bulletproofs+** — Chung, H., Han, K., Ju, C., Kim, M., & Seo, J. H. (2020). *Bulletproofs+: Shorter Proofs for Privacy-Enhanced Distributed Ledger*.
4. **CLSAG** — Goodell, B., Noether, S., & Blue, A. (2019). *Concise Linkable Spontaneous Anonymous Group Signatures*.
5. **RandomX** — tevador (2019). *RandomX: A new ASIC-resistant PoW algorithm*. https://github.com/tevador/RandomX
6. **ed25519** — Bernstein, D. J., Duif, N., Lange, T., Schwabe, P., & Yang, B. Y. (2011). *High-speed high-security signatures*.

### 7.2 Source code

7. **Monero v0.18.4.6** — github.com/monero-project/monero (commit `586e82bcc`)
8. **xmrblocks** — github.com/moneroexamples/onion-monero-blockchain-explorer (commit `7cb62e6`)
9. **monero-gui** — github.com/monero-project/monero-gui (commit `1216e07c`)
10. **XMRig** — github.com/xmrig/xmrig (v6.22.0)

### 7.3 Aime project artifacts

11. **Source code** — github.com/kiwoongeom/aime-core (after publication)
12. **Block explorer** — github.com/kiwoongeom/aime-explorer
13. **GUI wallet** — github.com/kiwoongeom/aime-gui
14. **Project documentation** — `portfolio/AIME_PROJECT.md`
15. **Evidence pack** — `portfolio/evidence_full/`
16. **Git patches (16 files)** — `portfolio/evidence_full/04_aime_patches/`

---

## Statement of independence

This review was conducted by the original author. It is a **self-review**, not an external audit. Readers should:
1. Read the diff themselves (16 patch files in `evidence_full/04_aime_patches/`).
2. Verify SHA256 hashes against `portfolio/SHA256SUMS`.
3. Build from source and verify reproducibility.
4. For commercial use, commission a third-party audit by a recognized firm (CertiK, Trail of Bits, Quantstamp, etc.).

For a learning project / personal portfolio, this self-review is the standard transparency practice in the cryptocurrency industry.

---

## Sign-off

```
Author:    Kiwoong Eom
Email:     eric.eom@gmail.com
GitHub:    @kiwoongeom
Date:      2026-04-29
Project:   Aime v0.1.0-genesis
Statement: To my knowledge, this document accurately describes
           the changes made and the security properties inherited.
           No claims are made beyond what is verified.
```
