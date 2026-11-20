#!/usr/bin/env bash
# 一键自检：链参数 → 出块 → 发交易 → 回执，全链路走一遍
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RPC="${RPC:-http://127.0.0.1:8545}"

rpc() { curl -s -X POST "$RPC" -H 'Content-Type: application/json' -d "$1"; }

CHAINID=$(rpc '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | python3 -c "import sys,json;print(int(json.load(sys.stdin)['result'],16))")
H1=$(rpc '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | python3 -c "import sys,json;print(int(json.load(sys.stdin)['result'],16))")
MINING=$(rpc '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' | python3 -c "import sys,json;print(json.load(sys.stdin)['result'])")
echo "[1] chainId=$CHAINID  height=$H1  mining=$MINING"
[ "$MINING" = "True" ] || { echo "未在出块：确认 04-start-sealer.sh 已启动且账户已解锁"; exit 1; }

sleep 4
H2=$(rpc '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | python3 -c "import sys,json;print(int(json.load(sys.stdin)['result'],16))")
[ "$H2" -gt "$H1" ] && echo "[2] 出块正常：$H1 → $H2" || { echo "[2] 4 秒内没出新块，检查 period 与日志"; exit 1; }

ADDR=$(cat "$ROOT/.address" 2>/dev/null || true)
[ -z "$ADDR" ] && { echo "缺少 .address，先跑 01-new-account.sh"; exit 1; }
TX=$(rpc "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$ADDR\",\"to\":\"0x000000000000000000000000000000000000dEaD\",\"value\":\"0x1\"}],\"id\":1}" \
      | python3 -c "import sys,json;print(json.load(sys.stdin).get('result',''))")
[ -z "$TX" ] && { echo "[3] 发交易失败（账户可能未解锁）"; exit 1; }
echo "[3] 交易已提交：$TX"

for i in $(seq 1 20); do
  R=$(rpc "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX\"],\"id\":1}")
  ST=$(echo "$R" | python3 -c "import sys,json;r=json.load(sys.stdin).get('result');print('' if not r else r['status'])")
  if [ -n "$ST" ]; then
    echo "[4] 回执 status=$ST block=$(echo "$R" | python3 -c "import sys,json;print(int(json.load(sys.stdin)['result']['blockNumber'],16))")"
    [ "$ST" = "0x1" ] && echo "全部通过：链在出块、交易能打包。" && exit 0
    echo "[4] 交易回执为失败"; exit 1
  fi
  sleep 3
done
echo "[4] 20 次轮询仍未出回执，检查节点日志"; exit 1
