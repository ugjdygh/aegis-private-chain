#!/usr/bin/env bash
# 生成密封账户（keystore 独立存放，重建链数据不会丢私钥）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="${KEYSTORE:-$ROOT/keystore}"
mkdir -p "$KEYSTORE"

if [ ! -f "$ROOT/password.txt" ]; then
  head -c 24 /dev/urandom | base64 | tr -d '\n' > "$ROOT/password.txt"
  echo "已生成 password.txt（丢失则账户不可恢复，请备份）"
fi

geth --keystore "$KEYSTORE" account new --password "$ROOT/password.txt" 2>&1 | tee "$ROOT/.account.log" >/dev/null

ADDR=$(grep -oE '0x[0-9a-fA-F]{40}' "$ROOT/.account.log" | tail -1 || true)
if [ -z "$ADDR" ]; then
  # 兼容不同版本输出格式：直接从 keystore 文件名解析
  ADDR="0x$(ls "$KEYSTORE" | grep -oE '[0-9a-fA-F]{40}' | tail -1)"
fi
echo "$ADDR" > "$ROOT/.address"
echo "密封账户: $ADDR"
echo "keystore: $KEYSTORE"
