#!/usr/bin/env bash
# 优雅停止本目录的节点（只杀本包 datadir 的 geth，不动别处的 geth）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for RPC in "${RPC:-http://127.0.0.1:8545}" http://127.0.0.1:8546; do
  curl -s -m 3 -X POST -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"admin_stopRPC","params":[],"id":1}' "$RPC" >/dev/null 2>&1 || true
done
pkill -f "geth --datadir $ROOT/chaindata" || true
pkill -f "geth --datadir $ROOT/chaindata-node2" || true
sleep 1
pgrep -af "geth --datadir $ROOT" || echo "已停止本目录的 geth 进程"
