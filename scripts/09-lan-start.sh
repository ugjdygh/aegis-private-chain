#!/usr/bin/env bash
# 让链能被手机连：RPC 监听 0.0.0.0（仅建议在自家 WiFi 或已做隧道时使用）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATADIR="${DATADIR:-$ROOT/chaindata}"
KEYSTORE="${KEYSTORE:-$ROOT/keystore}"
HTTP_PORT="${HTTP_PORT:-8545}"
P2P_PORT="${P2P_PORT:-30303}"
NETWORKID="${NETWORKID:-20270}"

ADDR="${ADDR:-$(cat "$ROOT/.address" 2>/dev/null || true)}"
if [ -z "$ADDR" ]; then
  ADDR="0x$(ls "$KEYSTORE" 2>/dev/null | grep -oE '[0-9a-fA-F]{40}' | tail -1 || true)"
fi
[ -z "$ADDR" ] && { echo "未找到账户，先跑 01-new-account.sh"; exit 1; }
[ -d "$DATADIR/geth/chaindata" ] || { echo "链未初始化，先跑 03-init-chain.sh"; exit 1; }
if ! { [ -n "$( { geth --help 2>&1 || true; } | grep -- '--unlock' || true )" ]; }; then
  echo "当前 geth 版本不支持 --unlock / Clique 密封，请装 1.13.15（见 README 版本适配）"; exit 1
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="<这台机器的局域网 IP>"

cat <<TIP

对外监听已开启，手机上这样填：
  网络名    AEGIS 私链
  RPC URL   http://$IP:$HTTP_PORT
  Chain ID  $NETWORKID
  货币符号  ETH
  区块浏览器 留空

手机必须和这台机器在同一个 WiFi；连不上先 ping 这个 IP。
只想临时试，建议改用隧道（见 README「手机上用」），别把 $HTTP_PORT 暴露到公网。
用 Ctrl+C 停止。

TIP

exec geth --datadir "$DATADIR" --keystore "$KEYSTORE" \
  --networkid "$NETWORKID" --port "$P2P_PORT" \
  --http --http.addr 0.0.0.0 --http.port "$HTTP_PORT" \
  --http.vhosts '*' --http.corsdomain '*' \
  --http.api eth,net,web3,txpool,personal,clique \
  --unlock "$ADDR" --password "$ROOT/password.txt" \
  --allow-insecure-unlock \
  --mine --miner.etherbase "$ADDR" \
  --verbosity 3
