#!/usr/bin/env bash
# 生成 genesis.json：预置余额 + 把密封账户写进 Clique extraData
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${1:-$(cat "$ROOT/.address" 2>/dev/null || true)}"
BALANCE="${BALANCE:-0x33b2e3c9fd0803ce8000000}"   # 1e26 wei ≈ 1 亿 ETH 单位
CHAINID="${CHAINID:-20270}"
PERIOD="${PERIOD:-3}"
PROFILE="${PROFILE:-legacy}"   # legacy=geth<=1.13 可出块的 PoA；modern=给 1.14+ 的合并后配置（仅供 init 参考）

if [ -z "$ADDR" ]; then echo "缺少地址：先跑 01-new-account.sh，或用 ADDR=0x... 指定"; exit 1; fi
ADDR_HEX=$(echo "$ADDR" | sed 's/^0x//' | tr 'A-F' 'a-f')

python3 - "$ROOT" "$ADDR_HEX" "$BALANCE" "$CHAINID" "$PERIOD" "$PROFILE" <<'PY'
import json, sys
root, addr, balance, chainid, period, profile = sys.argv[1:7]
gen = json.load(open(f"{root}/genesis.template.json"))
if profile == "legacy":
    # geth <= 1.13 的 PoA 私链：Clique 不支持 shanghai/cancun 区块结构，
    # 去掉这些字段才是纯 London 链（合约需用 evmVersion=london 编译）
    for k in ("blobSchedule", "terminalTotalDifficulty", "mergeNetsplitBlock", "shanghaiTime", "cancunTime"):
        gen["config"].pop(k, None)
gen["config"]["chainId"] = int(chainid)
gen["config"]["clique"]["period"] = int(period)
gen["alloc"] = {addr: {"balance": balance}}
# Clique extraData 结构 = 32 字节任意值 + 20 字节签名人 + 65 字节签名占位
gen["extraData"] = "0x" + "00" * 32 + addr + "00" * 65
json.dump(gen, open(f"{root}/genesis.json", "w"), indent=2)
print(f"genesis.json 已生成：chainId={chainid}, period={period}s, profile={profile}, signer=0x{addr}")
PY
