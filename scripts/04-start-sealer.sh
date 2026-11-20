#!/usr/bin/env bash
# 启动出块节点（Clique PoA），RPC 仅监听本机
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATADIR="${DATADIR:-$ROOT/chaindata}"
KEYSTORE="${KEYSTORE:-$ROOT/keystore}"
HTTP_PORT="${HTTP_PORT:-8545}"
P2P_PORT="${P2P_PORT:-30303}"
NETWORKID="${NETWORKID:-20270}"

ADDR=$(cat "$ROOT/.address" 2>/dev/null || true)
if [ -z "$ADDR" ]; then
  ADDR="0x$(ls "$KEYSTORE" 2>/dev/null | grep -oE '[0-9a-fA-F]{40}' | tail -1 || true)"
fi
if [ -z "$ADDR" ]; then echo "未找到账户，先跑 01-new-account.sh"; exit 1; fi
if [ ! -d "$DATADIR/geth/chaindata" ]; then echo "链未初始化，先跑 03-init-chain.sh"; exit 1; fi

# 版本适配：geth >= 1.14 已不支持 PoA 出块，>= 1.16 连 --unlock 都删了
if ! { [ -n "$( { geth --help 2>&1 || true; } | grep -- '--unlock' || true )" ]; }; then
  echo "当前 geth 版本不支持 --unlock / Clique 本地密封。"
  echo "请装 1.13.x（1.14 起已不支持 PoA 出块）："
  echo "  GOTOOLCHAIN=go1.21.13 go install github.com/ethereum/go-ethereum/cmd/geth@v1.13.15"
  echo "  或  docker run -it -p 8545:8545 ethereum/client-go:v1.13.15 ..."
  echo "若只想快速跑合约，改用 make dev（geth --dev）或 anvil。"
  exit 1
fi

echo "启动出块节点 $ADDR"
echo "RPC http://127.0.0.1:$HTTP_PORT | P2P $P2P_PORT | networkid $NETWORKID"
exec geth --datadir "$DATADIR" --keystore "$KEYSTORE" \
  --networkid "$NETWORKID" \
  --port "$P2P_PORT" \
  --http --http.addr 127.0.0.1 --http.port "$HTTP_PORT" \
  --http.api eth,net,web3,txpool,personal,clique,admin \
  --http.vhosts localhost,127.0.0.1 \
  --http.corsdomain "http://127.0.0.1:8080,http://localhost:8080" \
  --unlock "$ADDR" --password "$ROOT/password.txt" \
  --allow-insecure-unlock \
  --mine --miner.etherbase "$ADDR" \
  --verbosity 3
