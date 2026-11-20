#!/usr/bin/env bash
# 查链状态：高度、出块人、账户、余额
set -uo pipefail
RPC="${RPC:-http://127.0.0.1:8545}"
rpc() { curl -s -m 5 -X POST -H 'Content-Type: application/json' --data "$1" "$RPC" | jq -r "$2"; }

CID=$(rpc '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' '.result')
if [ "$CID" = "" ] || [ "$CID" = "null" ]; then
  echo "节点未响应（$RPC）。先确认 04-start-sealer.sh 已运行。"; exit 1
fi
echo "chainId      : $((CID))"
echo "blockNumber  : $(( $(rpc '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' '.result') ))"
echo "peerCount    : $(( $(rpc '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' '.result') ))"
echo "mining       : $(rpc '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' '.result')"
echo "signers      : $(rpc '{"jsonrpc":"2.0","method":"clique_getSigners","params":["latest"],"id":1}' '.result | join(", ")')"
echo "accounts     :"
for a in $(curl -s -m 5 -X POST -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' "$RPC" | jq -r '.result[]'); do
  bal=$(rpc "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$a\",\"latest\"],\"id\":1}" '.result')
  echo "  $a  balance=$(python3 -c "print(int('$bal',16)/1e18)")"
done
