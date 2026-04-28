# Aime RPC API Reference

> Aime daemon (`aimed`) and wallet RPC (`aime-wallet-rpc`) expose JSON-RPC and REST endpoints
> compatible with Monero's API spec.

---

## Daemon RPC (port 17081)

### REST Endpoints (GET/POST direct)

| Endpoint | Method | Purpose |
|---|---|---|
| `/get_info` | GET | Chain status |
| `/get_height` | GET/POST | Current chain height |
| `/get_blocks.bin` | POST | Bulk blocks (binary) |
| `/get_outs` | POST | Output details |
| `/get_transactions` | POST | Tx details by hash |
| `/start_mining` | POST | Start built-in miner |
| `/stop_mining` | POST | Stop miner |
| `/mining_status` | GET | Miner state |
| `/save_bc` | POST | Force flush DB to disk |
| `/get_peer_list` | GET | Known peers |

### JSON-RPC (POST /json_rpc)

Format:
```json
{
    "jsonrpc": "2.0",
    "id": "0",
    "method": "<method_name>",
    "params": { ... }
}
```

#### Block-related

| Method | Params | Returns |
|---|---|---|
| `get_block_count` | (none) | `{count, status}` |
| `get_block_template` | `wallet_address`, `reserve_size` | Candidate block for mining |
| `submit_block` | `[block_hex]` | Submit mined block |
| `get_block_header_by_hash` | `hash` | Block header by hash |
| `get_block_header_by_height` | `height` | Block header by height |
| `get_block` | `height` or `hash` | Full block with txs |
| `get_last_block_header` | (none) | Latest block header |

#### Network/peer

| Method | Returns |
|---|---|
| `get_connections` | List of P2P peers |
| `get_info` | Comprehensive chain state |
| `set_log_level` | Adjust logging |
| `get_bans` | IP ban list |
| `set_bans` | Add/remove IP bans |

#### Transaction pool

| Method | Returns |
|---|---|
| `get_transaction_pool` | All mempool txs |
| `get_transaction_pool_stats` | Mempool summary |
| `flush_txpool` | Clear specific txs from pool |

---

## Wallet RPC (port custom, default 18082 for Monero, can use any)

Run separately:
```bash
aime-wallet-rpc --rpc-bind-port 28083 \
                --wallet-file mywallet \
                --password "yourpw" \
                --daemon-address 127.0.0.1:17081
```

### JSON-RPC methods

#### Balance & address

| Method | Returns |
|---|---|
| `get_balance` | `{balance, unlocked_balance, multisig_import_needed, ...}` |
| `get_address` | Wallet primary address + sub-addresses |
| `create_address` | Generate new sub-address |
| `label_address` | Set label on a sub-address |

#### Transactions

| Method | Returns |
|---|---|
| `transfer` | Send AIME (single recipient) |
| `transfer_split` | Send AIME (multiple recipients or split) |
| `relay_tx` | Re-broadcast a tx |
| `get_transfers` | List wallet transactions |
| `get_transfer_by_txid` | Specific tx detail |
| `get_payments` | Payment ID specific |
| `incoming_transfers` | List of incoming UTXOs |

#### Wallet management

| Method | Action |
|---|---|
| `create_wallet` | Create new wallet (when running with no wallet) |
| `open_wallet` | Open existing |
| `close_wallet` | Close current |
| `change_wallet_password` | Self-explanatory |
| `restore_deterministic_wallet` | From seed |

---

## Examples

### Get chain state

```bash
curl http://127.0.0.1:17081/get_info | jq

{
  "alt_blocks_count": 0,
  "block_size_limit": 600000,
  "block_size_median": 300000,
  "bootstrap_daemon_address": "",
  "cumulative_difficulty": 1,
  "difficulty": 1,
  "height": 1,
  "incoming_connections_count": 0,
  "outgoing_connections_count": 0,
  "status": "OK",
  "target": 60,
  "target_height": 0,
  "top_block_hash": "b78e36c0afe10470ec6dcc71c8ae8c1e4847d979aa788deb67dfa837bdcdfb29",
  ...
}
```

### Get genesis block

```bash
curl -X POST http://127.0.0.1:17081/json_rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0","id":"0",
    "method":"get_block_header_by_height",
    "params":{"height":0}
  }'
```

### Start mining

```bash
curl -X POST http://127.0.0.1:17081/start_mining \
  -H "Content-Type: application/json" \
  -d '{
    "miner_address":"AQWWPyLG4exW1QNg2HZnG...",
    "threads_count":4,
    "do_background_mining":false,
    "ignore_battery":true
  }'

# {"status":"OK","untrusted":false}
```

### Send a transaction (via wallet RPC)

```bash
curl -X POST http://127.0.0.1:28083/json_rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0","id":"0",
    "method":"transfer",
    "params":{
      "destinations":[{"amount":1000000000000,"address":"AbCdEf..."}],
      "priority":1,
      "ring_size":16
    }
  }'
```

> Amounts are in atomic units. 1 AIME = 10^12 atomic.

---

## Restricted RPC

When daemon is started with `--restricted-rpc`, the following methods are blocked:

- `start_mining`, `stop_mining`
- `set_log_level`, `set_bans`
- `flush_txpool`
- `save_bc`
- `submit_block` (only from authorized peers)
- Several other administrative methods

This is suitable for public-facing nodes (e.g., your block explorer's daemon). Private mining nodes should NOT use restricted mode.

---

## Authentication (optional)

For wallet RPC and daemon RPC over public network:

```bash
aime-wallet-rpc --rpc-login user:password \
                ...
```

Then:

```bash
curl -u user:password ...
```

For digest auth (more secure than basic):

```bash
aime-wallet-rpc --rpc-login user:password
# Use curl with --digest flag
```

For TLS:

```bash
aime-wallet-rpc --rpc-ssl enabled \
                --rpc-ssl-private-key /path/to/key.pem \
                --rpc-ssl-certificate /path/to/cert.pem \
                ...
```

---

## ZMQ Pub/Sub (port 17082)

For real-time event subscriptions (e.g., new blocks):

```python
import zmq
ctx = zmq.Context()
sub = ctx.socket(zmq.SUB)
sub.connect("tcp://127.0.0.1:17082")
sub.subscribe("json-minimal-chain_main")
sub.subscribe("json-minimal-txpool_add")

while True:
    msg = sub.recv_multipart()
    print(msg)
```

Topics:
- `json-minimal-chain_main` — new blocks
- `json-minimal-txpool_add` — new mempool txs
- `json-full-chain_main` — full block data
- (more — see Monero ZMQ docs)

---

## Compatibility with Monero Tools

Because Aime uses identical RPC API as Monero v0.18:
- **xmrig** miner works (just point at aimed RPC)
- **monero-wallet-cli** can technically connect (but address format will mismatch)
- **xmrblocks** explorer works (with patches in our fork)
- Any Monero RPC library should work — Python (monero), JS (monero-rpc), etc.

---

## Rate Limits

The daemon has no built-in rate limits, but for public nodes consider:
- nginx/Caddy reverse proxy with rate limiting
- Cloudflare in front
- `--rpc-payment-address <ADDR>` to require RPC payments (advanced)

---

## See Also

- Monero RPC docs: https://docs.getmonero.org/rpc-library/monero-wallet-rpc/
- These largely apply to Aime as well, with these differences:
  - Address prefix 56 (instead of 18)
  - Default ports 17080-17082
  - Network ID `1dd945d7-...`
