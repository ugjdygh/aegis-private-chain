#!/usr/bin/env bash
# 初始化链数据（keystore 独立，重建不影响私钥）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATADIR="${DATADIR:-$ROOT/chaindata}"

[ -f "$ROOT/genesis.json" ] || { echo "缺少 genesis.json，先跑 02-build-genesis.sh"; exit 1; }
if [ -d "$DATADIR/geth/chaindata" ]; then
  echo "已初始化，跳过（要重建先 make reset）"; exit 0
fi
mkdir -p "$DATADIR"
geth --datadir "$DATADIR" init "$ROOT/genesis.json" 2>&1 | tail -3
echo "初始化完成：$DATADIR"
