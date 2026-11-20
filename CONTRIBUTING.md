# 贡献指南

## 环境

- geth **1.13.15**（1.14 起已不支持 Clique PoA 出块，1.16 起连 `--unlock` 都删了）
- Go 1.21（编译 1.13 必须锁这个工具链，否则 `memsize` 链接失败）
- bash 4+、python3（只用来生成 genesis.json）

## 提交前自检

```bash
shellcheck scripts/*.sh          # 可选但推荐
bash -n scripts/*.sh             # 语法检查
make account && make genesis && make init && make start && make selftest
```

`make selftest` 四项全过（chainId / 出块 / 发交易 / 回执）才算跑通，改动涉及 genesis 或启动参数时尤其要跑。

## 改动约定

- 脚本保持"一条命令一个动作"，不引入隐藏的全局状态；新增参数一律走环境变量并给默认值。
- 任何会删数据的操作（`reset`）必须只删 `chaindata/`，**不许碰 `keystore/`**。
- 私有链是测试环境，不接收任何关于"链上不可篡改""生产可用"的表述改动。
- 提交信息用一句话说清改了什么、为什么，例如 `fix: 第二节点错开 authrpc 端口，避免抢 8551`。

## 不要提交

`chaindata/`、`keystore/`、`password.txt`、`.address`、`genesis.json`（这些都是本机个人数据，已在 `.gitignore` 中排除）。
