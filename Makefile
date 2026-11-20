# 私有链常用操作
ADDR ?=
ENODE ?=
RPC ?= http://127.0.0.1:8545

account:      ## 1 生成密封账户与密码
	./scripts/01-new-account.sh
genesis:      ## 2 生成 genesis.json（可用 ADDR=0x... 指定，BALANCE=0x... 改预置余额）
	./scripts/02-build-genesis.sh $(ADDR)
init:         ## 3 初始化链数据
	./scripts/03-init-chain.sh
start:        ## 4 启动密封节点（前台）
	./scripts/04-start-sealer.sh
status:       ## 5 查看链状态
	./scripts/05-status.sh
node2:        ## 6 起第二节点并连入：make node2 ENODE=enode://...
	./scripts/06-connect-second-node.sh $(ENODE)
stop:
	./scripts/07-stop.sh
backup:       ## 备份私钥与链数据
	@mkdir -p backup && tar czf backup/private-chain-$(shell date +%Y%m%d-%H%M).tgz chaindata/keystore password.txt genesis.json && ls -lh backup | tail -2
reset:        ## 清空链数据（不可逆，先 backup）
	@read -p "确认删除 chaindata* ？[y/N] " y; [ "$$y" = "y" ] && rm -rf chaindata chaindata-node2 && echo "已清空" || echo "已取消"
help:
	@grep -E '^[a-zA-Z0-9_]+:.*##' $(MAKEFILE_LIST) | awk -F':.*##' '{printf "  %-10s %s\n", $1, $2}'
.PHONY: account genesis init start status node2 stop backup reset help lan selftest dev install

lan:          ## 对外监听 0.0.0.0，供手机/同网设备连接（会打印 RPC 地址）
	./scripts/09-lan-start.sh

selftest:     ## 一键自检：chainId/出块/发交易/回执
	./scripts/08-selftest.sh

dev:          ## 用最新版 geth 的 --dev 模式临时链（chainId 1337，退出即丢）
	geth --dev --dev.period 1 --http --http.addr 127.0.0.1 --http.port 8545 \
	  --http.api eth,net,web3,txpool,personal --http.corsdomain "http://127.0.0.1:8080"
install:      ## 安装可跑 PoA 的 geth 版本
	./scripts/00-install-geth.sh
