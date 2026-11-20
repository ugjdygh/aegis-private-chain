#!/usr/bin/env bash
# 起第二个节点并连接到第一个（同一 genesis、同一 networkid）
# 注意 --authrpc.port 必须错开，否则会和节点1 抢 8551 端口启动失败
# 用法: ./06-connect-second-node.sh <node1 的 enode>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENODE="${1:-}"
D2="$ROOT/chaindata-node2"
[ -z "$ENODE" ] && { echo "用法: $0 enode://<pubkey>@127.0.0.1:30303"; exit 1; }

mkdir -p "$D2"
[ -d "$D2/geth/chaindata" ] || geth --datadir "$D2" init "$ROOT/genesis.json"

echo "第二个节点启动中（RPC 8546，P2P 30304）"
exec geth --datadir "$D2" \
  --networkid "${NETWORKID:-20270}" \
  --port 30304 \
  --bootnodes "$ENODE" \
  --http --http.addr 127.0.0.1 --http.port 8546 \
  --authrpc.port 8552 \
  --http.api eth,net,web3,admin \
  --http.vhosts localhost,127.0.0.1 \
  --verbosity 3
