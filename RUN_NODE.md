# Running an Aime Node

> A full node validates the Aime blockchain and participates in P2P propagation.
> Running one strengthens the network and gives you trustless RPC access.

---

## Quick Start

```bash
./aimed
```

That's it for default settings. Daemon binds to:
- `127.0.0.1:17080` (P2P, listen — but only loopback)
- `127.0.0.1:17081` (RPC)
- `127.0.0.1:17082` (ZMQ)

For others to connect to your node, you need to expose 17080 publicly (see "Public Seed Node" below).

---

## Configurations

### Local Private Node

```bash
./aimed --offline --no-igd
```
- No P2P connections (offline)
- No UPnP attempts

Use case: testing, isolated experiments.

### Local Node That Accepts Connections

```bash
./aimed \
  --p2p-bind-ip 127.0.0.1 \
  --p2p-bind-port 17080 \
  --rpc-bind-ip 127.0.0.1 \
  --rpc-bind-port 17081 \
  --no-igd \
  --allow-local-ip
```

Use case: running 2 nodes on same machine for testing.

### Public Seed Node

```bash
./aimed \
  --p2p-bind-ip 0.0.0.0 \
  --p2p-bind-port 17080 \
  --confirm-external-bind \
  --rpc-bind-ip 127.0.0.1 \
  --rpc-bind-port 17081 \
  --restricted-rpc \
  --hide-my-port \
  --detach \
  --pidfile /var/run/aimed.pid
```

- Listens on all interfaces (public IP)
- Restricted RPC (only safe methods open)
- Detached (background) with PID file
- Hide own port (modest privacy)

**Required:** open inbound TCP 17080 on firewall:

```bash
# UFW
sudo ufw allow 17080/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 17080 -j ACCEPT
```

### Connect to Existing Seed

```bash
./aimed \
  --add-priority-node <SEED_IP>:17080 \
  --p2p-bind-port 17081
```

Useful for joining an established Aime network.

---

## Hardware Requirements

| Use case | RAM | Disk | CPU |
|---|---|---|---|
| Validation only (no mining) | 1 GB | Growing (initially small) | 1 core |
| Validation + mining | 2 GB | Growing | 2+ cores |
| Public seed (bandwidth heavy) | 4 GB | 10+ GB | 2 cores, decent network |

Network usage:
- Outgoing: peers download blocks/txs (~100 MB/day at low usage)
- Incoming: peers ask for data (~500 MB/day for active seed)

---

## Useful CLI Commands (in interactive mode)

Run `aimed` without `--detach` to get the prompt, then:

```
status              # Quick chain status
print_height        # Current chain height
print_pl            # Peer list
print_cn            # Connections
hard_fork_info      # Hard fork progression
print_block <h>     # Detailed block view
sync_info           # Sync state
```

---

## RPC Examples

```bash
# Get info
curl http://127.0.0.1:17081/get_info

# Get block 0 (genesis)
curl -X POST http://127.0.0.1:17081/json_rpc \
  -d '{"jsonrpc":"2.0","id":"0","method":"get_block_header_by_height","params":{"height":0}}'

# Submit a block (after mining externally)
curl -X POST http://127.0.0.1:17081/json_rpc \
  -d '{"jsonrpc":"2.0","id":"0","method":"submit_block","params":["<BLOCK_HEX>"]}'

# Get connections
curl -X POST http://127.0.0.1:17081/json_rpc \
  -d '{"jsonrpc":"2.0","id":"0","method":"get_connections"}'
```

Restricted RPC (`--restricted-rpc`) blocks methods like:
- `start_mining` / `stop_mining`
- `get_peer_list`
- Wallet RPC operations
- Block/tx submission (if not from authorized peers)

---

## Monitoring

Quick health check script:

```bash
#!/bin/bash
# /usr/local/bin/aimed-health
H=$(curl -s http://127.0.0.1:17081/get_info | python3 -c "import json,sys;print(json.load(sys.stdin).get('height',0))")
P=$(curl -s http://127.0.0.1:17081/get_info | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('outgoing_connections_count',0)+d.get('incoming_connections_count',0))")
echo "height=$H peers=$P"

if [ "$H" -lt 1 ] || [ "$P" -lt 1 ]; then
    echo "WARN: chain not progressing or no peers" >&2
    exit 1
fi
```

Run periodically via cron:

```cron
*/5 * * * * /usr/local/bin/aimed-health || systemctl restart aimed
```

---

## Systemd Service

`/etc/systemd/system/aimed.service`:

```ini
[Unit]
Description=Aime Daemon
After=network.target

[Service]
Type=forking
User=aime
ExecStart=/usr/local/bin/aimed \
  --p2p-bind-ip 0.0.0.0 \
  --p2p-bind-port 17080 \
  --confirm-external-bind \
  --rpc-bind-ip 127.0.0.1 \
  --rpc-bind-port 17081 \
  --restricted-rpc \
  --detach \
  --pidfile /var/run/aimed.pid
PIDFile=/var/run/aimed.pid
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable aimed
sudo systemctl start aimed
sudo systemctl status aimed
```

---

## Backup

What to back up:
- `~/.aime/lmdb/` — blockchain (re-syncable, but huge)
- `~/.aime/wallet/` — your wallet keys (CRITICAL — losing means losing funds)
- 25-word seed (offline, paper) — wallet recovery anywhere

Don't back up:
- Logs (regrowable)
- Cache files

---

## Troubleshooting

### Daemon won't start
- Check port collision: `sudo lsof -i :17080`
- Check disk space: `df -h ~/.aime`
- Check log: `tail -50 ~/.aime/aime.log`

### No peers connecting
- Firewall blocking? `sudo ufw status`
- ISP blocking inbound? Try outbound-only: remove `--p2p-bind-ip 0.0.0.0`
- Add manual seeds: `--add-priority-node <known_seed>:17080`

### Chain not syncing
- Wrong NETWORK_ID? You may have rebuilt against vanilla Monero source
- Check daemon version matches network's expected version

### Disk filling up
- Pruning helps: add `--prune-blockchain`
- Saves ~70% disk space, sacrifices ability to serve full historical data

---

## Operating an Aime Seed Node (For Network Operators)

If you want to be one of the seed nodes that bootstraps new users:

1. Run on a stable VPS with public IP (Vultr/Hetzner/AWS Lightsail)
2. Open port 17080 inbound
3. Notify the community of your IP/domain
4. Maintain >99% uptime
5. Keep daemon updated to latest version

To get hardcoded as a "fixed seed" in future Aime releases:
- Submit PR to `src/p2p/net_node.inl::vSeeds`

---

## Network Etiquette

- **Don't ban without cause** — keep `--ban-list` empty unless attacked
- **Keep node updated** — outdated nodes can fork off the chain at hard forks
- **Report consensus bugs** — if your node disagrees with network, file an issue
- **Don't run vacuum nodes** — i.e., nodes that download but never serve data

---

Happy nodding! 🛰️
