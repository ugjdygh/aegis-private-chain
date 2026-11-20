#!/usr/bin/env bash
# 安装可跑 PoA 私有链的 geth（1.13.x）。三选一，任一条能成就够。
set -euo pipefail
VERSION="${VERSION:-v1.13.15}"
TOOLCHAIN="${TOOLCHAIN:-go1.21.13}"   # 1.13 用新 Go 编译会撞 memsize 链接错误，必须降到 1.21

if command -v geth >/dev/null 2>&1 && { [ -n "$( { geth --help 2>&1 || true; } | grep -- '--unlock' || true )" ]; }; then
  echo "已装可用版本：$(geth version | head -2 | tr '\n' ' ')"; exit 0
fi

echo "方式1：Go 安装（需 Go 1.21+）"
if command -v go >/dev/null 2>&1; then
  GOTOOLCHAIN="$TOOLCHAIN" GOBIN="${GOBIN:-$HOME/go/bin}" go install "github.com/ethereum/go-ethereum/cmd/geth@${VERSION}"
  echo "已安装到 $GOBIN/geth，记得把该目录加入 PATH"; exit 0
fi

echo "方式2：Docker（无需本地编译，推荐给不想折腾 Go 的情况）"
echo "  docker run -it --rm -v \$PWD/chaindata:/root/.ethereum -p 8545:8545 \\"
echo "    ethereum/client-go:v1.13.15 --datadir /root/.ethereum --http --http.addr 0.0.0.0 \\"
echo "    --http.api eth,net,web3,personal --networkid 20270"
echo "方式3：预编译二进制"
echo "  https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.15-<hash>.tar.gz"
echo "  # 或从 GitHub Releases v1.13.15 页面下载对应平台包，解压即用"
echo "注意：最新版 geth(1.14+) 已不能跑 PoA 私链，别装 latest。"
