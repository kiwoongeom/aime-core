# Aime Patches

These are the git format-patch files representing every Aime-specific commit,
in chronological order. Apply with `git am` to a Monero v0.18.4.6 checkout to
recreate the Aime daemon.

## Contents

| Patch | Phase | Description |
|---|---|---|
| 0001-Phase-4-... | 4 | Binary names + data directory rebrand |
| 0002-Phase-5-... | 5 | Network identifiers (ports, NETWORK_ID, address prefix) |
| 0003-Phase-6-... | 6 | Custom GENESIS_TX with Aime message |
| 0004-Phase-8-... | 8 | Disable Monero hardcoded checkpoints |
| 0005-Phase-9-... | 9 | Bypass is_synchronized check (fresh chain) |
| 0006-Phase-11+16-... | 11+16 | Polish + seed/checkpoint placeholders |
| 0007-v0.1.0-... | release | Author attribution + CHANGELOG |

For full inheritance discussion and risk assessment, see
[../INHERITANCE_AND_REVIEW.md](../INHERITANCE_AND_REVIEW.md).
