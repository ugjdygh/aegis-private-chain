# v0.1.0 — 首个可用版本

一条用 go-ethereum 自建的 Clique PoA 私有链，从建账户到出块、组网、手机接入全部脚本化，并在 geth **1.13.15** 上逐项实测通过。

## 这一版有什么

- **10 个脚本，一条命令一个动作**：`00-install-geth` → `09-lan-start`，覆盖装 geth、建账户、生成创世、初始化、启动出块、查状态、加第二节点、停止、自检、对外监听。
- **`make selftest`**：自动跑「chainId → 出块 → 发交易 → 回执」四步，全过才算链是活的。
- **手机三路线**：电脑跑链+同 WiFi（`make lan`）、云主机+tailscale 隧道、Termux 随身跑。
- **两档 genesis 配置**：`legacy`（可出块，纯 London）、`modern`（1.14+ 合并后配置，仅供对照）。

## 版本红线

| geth | 能否自建 PoA 私链出块 |
| --- | --- |
| 1.13.x | ✅ 本版本实测通过 |
| 1.14 / 1.15 | ❌ `only PoS networks are supported` |
| 1.16+ | ❌ `--unlock` 与 `clef` 均已移除 |

编译 1.13 必须锁 `GOTOOLCHAIN=go1.21.13`，否则 `memsize` 链接失败。

## 实测记录

| 步骤 | 结果 |
| --- | --- |
| 建账户 / 生成创世 / init | `Successfully wrote genesis state hash=c1dfc9..5b56b0` |
| 启动出块 | 每 3 秒一块，`mining=true`，`clique.getSigners()` 返回本账户 |
| 转账 0.5 ETH | `status=0x1`，`gasUsed=21000` |
| 第二节点组网 | 与节点1 高度一致（同为第 19 块） |
| 部 ERC-20 | `status=0x1`，`totalSupply()` = 1,000,000 |
| `make selftest` | 四项全通过 |

## 已知限制

- Clique 不支持 shanghai/cancun 区块结构，链是纯 London：合约需 `evmVersion: "london"` 编译，否则 PUSH0 是非法指令。
- 私有链没有经济安全，仅用于开发与内部验证；不对公网开放 RPC，不做代币募资。
- Windows 原生未验证，建议 WSL。

## 安装

```bash
git clone https://github.com/ugjdygh/aegis-private-chain.git
cd aegis-private-chain
make install && make account && make genesis && make init
make start          # 另开终端
make status && make selftest
```
