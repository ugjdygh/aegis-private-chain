# AEGIS 私有链（go-ethereum / Clique PoA）

一条自己完全掌控的以太坊兼容链：**自己定 chainId、自己当出块人、数据只在本机/内网**。
适合做 DApp 联调、合约预演、内部演示，不接主网。

## 实测记录（2026-11-20，本机实际跑过，不是纸上方案）

| 步骤 | 结果 |
| --- | --- |
| `make account` | 生成密封账户 `0x9420…97f8` |
| `make genesis && make init` | `Successfully wrote genesis state hash=c1dfc9..5b56b0` |
| `make start` | 每 3 秒出一个块，`mining=true`，`clique.getSigners()` 返回本账户 |
| 发 0.5 ETH 转账 | 回执 `status=0x1`，`gasUsed=21000`，已进块 |
| 第二节点 | 同 genesis + `--bootnodes`，高度与节点1 同步一致（都是第 19 块） |
| 部一个 ERC-20（自写 AegisToken，solc 0.8.26 + evmVersion=london） | `status=0x1`，`totalSupply()` 读出 1,000,000 |
| `make selftest` | 四项全通过：chainId=20270 / 出块 / 交易 / 回执 |

三个必须记住的坑（都在脚本里修好了）：

1. **Clique 不认 shanghai/cancun 区块结构**：genesis 里写了 `shanghaiTime`，节点自己照出块，但邻居节点同步时报 `clique does not support shanghai fork` 直接断连。所以 legacy 档把 shanghai/cancun 全删掉，链是 **pure London** ——合约必须用 `evmVersion: "london"` 编译（`solc` 编译时加 `evmVersion: "london"`，否则 0.8.26 默认产出的 PUSH0 指令在这条链上是非法指令）。
2. **第二节点必须错开 `--authrpc.port`**：geth 默认都抢 8551，第二个节点直接 `bind: address already in use` 起不来。已固定成节点1=8551、节点2=8552。
3. `--unlock` 走 HTTP 会被 geth 拒绝（`Account unlock with HTTP access is forbidden!`），必须带 `--allow-insecure-unlock`；这只在 127.0.0.1 上安全，别照搬到公网。

## 与 `geth --dev` 的区别

| | `geth --dev` | 本私有链 |
| --- | --- | --- |
| 数据 | 临时目录，退出即丢 | `chaindata/` 持久化 |
| 账户 | 临时预置 | 你自己用 `account new` 生成 |
| 出块 | 1 秒自动，chainId 1337 | Clique PoA，`period` 秒一快，chainId 自定 |
| 多节点 | 不支持 | 支持，同一 genesis 组网 |
| 用途 | 一次跑通合约 | 长期联调 / 内部测试环境 |

## 版本适配（重要，先看这条）

go-ethereum 每个大版本都在收紧 PoA 私链能力，实测结论：

| geth 版本 | 能否自建 PoA 私链出块 | 表现 |
| --- | --- | --- |
| **1.13.x（推荐，本包默认）** | ✅ 可以 | `--unlock` + Clique 密封都还在 |
| 1.14.x / 1.15.x | ❌ 不行 | 启动即 `only PoS networks are supported` |
| 1.16 及以上（如 1.17.10） | ❌ 不行 | `--unlock` 被删、`clef` 也被删，只能接外部共识客户端 |

所以**先把 geth 锁到 1.13.15**，再跑本包脚本：

```bash
# 方式1（有 Go 环境，注意锁 go1.21 工具链，否则 memsize 链接失败）
GOTOOLCHAIN=go1.21.13 GOBIN=$HOME/go/bin go install github.com/ethereum/go-ethereum/cmd/geth@v1.13.15
export PATH=$HOME/go/bin:$PATH && geth version    # 应显示 1.13.15-stable

# 方式2（Docker，不污染本机）
docker run -it --rm -p 8545:8545 -p 30303:30303 \
  -v $PWD/chaindata:/root/.ethereum -v $PWD/keystore:/root/keystore \
  ethereum/client-go:v1.13.15 --datadir /root/.ethereum --keystore /root/keystore \
  --http --http.addr 0.0.0.0 --http.api eth,net,web3,personal,clique --networkid 20270
```

也可以 `make install` 一键安装。只想快速跑合约不管私链，用 `make dev`（最新版 geth 的 `--dev`）或 Foundry 的 `anvil --chain-id 20270`。

`04-start-sealer.sh` 自带能力探测：版本不支持 `--unlock` 会当场提示退出，不会让你跑到一半才报错。

## 快速开始（5 条命令）

```bash
make account        # 1 生成密封账户，密码写入 password.txt
make genesis        # 2 用该地址生成 genesis.json（预置 1 亿 ETH 等值余额）
make init           # 3 初始化 chaindata
make start          # 4 前台启动节点（另开终端）
make status         # 5 查看 chainId / 高度 / 出块人 / 账户
make selftest       # 6 自检：出块 + 发交易 + 回执（可选但推荐）
```

依赖：`geth 1.13.15`、`curl`、`jq`（`05-status.sh` 用）、`python3`（生成 genesis.json 用）、`bash 4+`。

默认：**chainId 20270，3 秒一个块，RPC http://127.0.0.1:8545，P2P 30303**。
想改：`CHAINID=8801 PERIOD=5 make genesis`。
`make genesis` 默认 `PROFILE=legacy`（geth ≤1.13 可出块）；`PROFILE=modern make genesis` 生成给 1.14+ 的合并后配置，只用于对照，不能出块。

## 参数为什么这么填

| 字段 | 值 | 说明 |
| --- | --- | --- |
| `config.chainId` | 20270 | 钱包/前端认网络的唯一标识，不能和主网 1、测试网 11155111 撞 |
| `clique.period` | 3 | 出块间隔（秒）。合约联调 3 秒够用；要快可设 1 |
| `clique.epoch` | 30000 | 每 N 块重算签名人集合，PoA 治理用 |
| `gasLimit` | `0x1c9c380` = 30,000,000 | 单块 gas 上限，够部 ERC-20 |
| `difficulty` | `0x1` | Clique 下只是占位，不代表挖矿难度 |
| `alloc` | 密封账户预置余额 | **POA 链发交易要付 gas，没有初始余额什么都做不了** |
| `terminalTotalDifficulty` | legacy 档不写 | 写了会被 1.14+ 判定为已转 PoS 而拒绝启动，1.13 则必须不写 |

> `01-new-account.sh` 的密码是随机生成的，存在 `password.txt`。**这个文件丢了账户就废了**，务必和 keystore 一起备份（`make backup`）。

## 手机上用：三条路线，按你的场景选

链本身是台"服务器"，手机当钱包/客户端；也可以把链塞进手机自己跑。先看你要哪种：

| 路线 | 需要什么 | 适合 |
| --- | --- | --- |
| **A. 电脑跑链 + 手机连同一 WiFi** | 一台开着机的电脑 | 在家/宿舍联调，最省事 |
| **B. 链跑云主机 + 隧道** | 云主机 + tailscale/ngrok 之一 | 人在外面也要连 |
| **C. 手机 Termux 自己跑链** | 安卓机 + Termux（约 100MB 空间） | 完全随身，不依赖任何网络 |

### A. 电脑跑链，手机连

1. 电脑上改用对外监听模式（会自动打印手机要填的地址）：

```bash
make lan          # 等价于 ./scripts/09-lan-start.sh
```

2. 手机装 **MetaMask**（或 TokenPocket / Trust），添加自定义网络：

```
网络名      AEGIS 私链
RPC URL     http://192.168.x.x:8545     ← make lan 打印的那个
Chain ID    20270                        ← 必须完全一致，错了钱包连不上
货币符号    ETH
浏览器      留空
```

3. 手机要能操作账户，就把 `keystore/UTC--...json` 这个文件和 `password.txt` 传到手机，
   MetaMask 选「导入账户 → JSON 文件」导入（geth 的 keystore 就是标准 v3 格式，能直接导）。
   **导进去等于把出块权也给了手机**——测试链无所谓，真资产别这么干。

4. 手机浏览器打开你自己的 DApp 前端（任何支持自定义 RPC 的 ethers/web3 页面都行），RPC 填同一个地址就能查余额、转账。

连不上的排查顺序：手机和电脑是否同一 WiFi → `ping 192.168.x.x` 通不通 → 电脑防火墙放行 8545 → 钱包里 Chain ID 是否 20270。

### B. 云主机 + 隧道（不想开公网端口）

```bash
# 云主机上装 tailscale，手机装同名 App 登同一账号
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
# 之后手机用 tailscale 分配的 100.x.x.x 地址连，不用开任何公网端口
```

ngrok 也行（`ngrok tcp 8545`），但免费版地址会变，每次都要改钱包配置。**别直接把 8545 映射到公网 0.0.0.0**，那等于把出块人账户敞开。

### C. 手机 Termux 自己跑链（真·随身）

```bash
pkg update && pkg install -y golang git curl
export GOTOOLCHAIN=go1.21.13        # 关键：Termux 默认 Go 太新，1.13 会链接失败
go install github.com/ethereum/go-ethereum/cmd/geth@v1.13.15
export PATH=$HOME/go/bin:$PATH && geth version   # 应显示 1.13.15-stable
```

然后把本包目录传到手机（`~/private-chain`），照原流程跑：

```bash
cd ~/private-chain && make account && make genesis && make init && make start
```

手机上的钱包直接连 `http://127.0.0.1:8545`（同机就是本机地址），chainId 20270。
嫌编译太慢的替代方案：装 Foundry 的 `anvil`（有 aarch64 预编译包），`anvil --chain-id 20270`，秒起一条本地链，出块即时、支持 `--dump-state` 持久化，缺点是行为与 geth 略有差异。

## 多节点组网

```bash
# 节点1 已启动后，取它的 enode
geth attach http://127.0.0.1:8545 --exec "admin.nodeInfo.enode"
# 形如 enode://<pubkey>@127.0.0.1:30303

make node2 ENODE="enode://<pubkey>@127.0.0.1:30303"
```

- 第二节点必须用**同一份 genesis.json**、**同一 networkid**，否则连上也同步不了
- 第二节点 RPC 在 8546，节点间靠 `--bootnodes` 发现
- 想让第二节点也出块：在节点1 的 console 里 `clique.propose("<节点2地址>", true)`，等 `epoch` 边界生效
- 内网多机：把 `--http.addr` 改成 `0.0.0.0`（仅内网），`--bootnodes` 里换成节点1 的内网 IP

## 安全要点（私链不等于安全）

1. **RPC 只绑 127.0.0.1**：脚本里 `--http.addr 127.0.0.1`、`--http.vhosts localhost,127.0.0.1`，别对外开 8545
2. **`personal`、`admin` API 只在内网开**：这两个能解锁账户、关节点
3. **别把 `password.txt` 提交到 Git**：已在 `.gitignore` 里排除
4. **keystore 定期备份**：`make backup` 打成 tar 包
5. **私有链没有经济安全**：出块人全在你手里，任何"链上不可篡改"的说法在这里都不成立，只当测试环境用

## 常用 console 命令

```bash
geth attach http://127.0.0.1:8545
```

```javascript
eth.blockNumber                       // 当前高度
eth.accounts                          // 账户列表
eth.getBalance(eth.accounts[0])       // 余额（wei）
clique.getSigners()                   // 当前出块人
admin.peers                           // 已连接节点
txpool.status                         // 交易池
miner.start(); miner.stop()           // 手动出块（PoA 下一般不需要）
```

## 故障对照表

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Fatal: Failed to unlock account` | 密码文件不对 / 路径错 | 检查 `password.txt` 与 `--password` 路径 |
| 高度一直 0 | 没加 `--mine`，或 `miner.etherbase` 不是密封账户 | 用 `04-start-sealer.sh` 启动 |
| 交易 pending 不打包 | period 太大或节点没在密封 | 确认 `eth_mining` 为 true |
| `invalid genesis` / 启动报 config 错 | genesis 字段缺失或与已有数据不匹配 | 改 genesis 后必须 `make reset` 重建 |
| 钱包连不上 | chainId 不一致 或 端口没监听 | 对 `eth_chainId` 与钱包设置 |
| 两个节点连上但不同步 | genesis 不同 / networkid 不同 | 统一 genesis.json 与 `--networkid` |
| `clique does not support shanghai fork` | genesis 带了 shanghaiTime | 用 `PROFILE=legacy` 重新生成并 `make reset` |
| 第二节点 `bind: address already in use` | 抢了 8551 | 已固定 `--authrpc.port 8552`，别删 |
| `account new` 报权限错 | datadir 归属问题 | 确认目录可写，别用 root 建的目录换普通用户跑 |

## 目录

```
private-chain/
├── genesis.template.json         # 链参数模板（02 脚本按 PROFILE 生成 genesis.json）
├── scripts/00-install-geth.sh    # 装可用版本 geth（1.13.15）
├── scripts/01~09*.sh             # 建账户 → 创世 → 初始化 → 启动 → 状态 → 加节点 → 停 → 自检 → 对外监听
├── Makefile
├── keystore/                     # 账户私钥（与 chaindata 分离，reset 不会误删）
└── chaindata/                    # 链数据，可随时重建
```

## 边界

自建私有链用于开发与内部验证：不做代币发行募资、不对接交易平台、不对公网开放 RPC。
