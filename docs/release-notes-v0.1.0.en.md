# v0.1.0 — First usable release

A scripted Clique PoA private chain on go-ethereum: from creating the sealer account to sealing blocks, multi-node networking and phone access, every step verified against geth **1.13.15**.

## What's in it

- **Ten scripts, one action each**: `00-install-geth` → `09-lan-start`, covering geth install, account creation, genesis generation, initialisation, sealing, status, second node, stop, self-test and LAN listening.
- **`make selftest`**: runs chainId → sealing → send tx → receipt automatically. The chain counts as alive only when all four pass.
- **Three phone routes**: desktop chain + same Wi-Fi (`make lan`), VPS + tailscale tunnel, or Termux on the phone itself.
- **Two genesis profiles**: `legacy` (sealable, pure London) and `modern` (post-merge config for 1.14+, reference only).

## Version red line

| geth | Can it seal a private PoA chain? |
| --- | --- |
| 1.13.x | ✅ verified in this release |
| 1.14 / 1.15 | ❌ `only PoS networks are supported` |
| 1.16+ | ❌ `--unlock` and `clef` both removed |

Building 1.13 requires `GOTOOLCHAIN=go1.21.13`, otherwise the link step fails on a `memsize` reference.

## Verified results

| Step | Result |
| --- | --- |
| account / genesis / init | `Successfully wrote genesis state hash=c1dfc9..5b56b0` |
| sealing | a block every 3s, `mining=true`, `clique.getSigners()` returns the local account |
| 0.5 ETH transfer | `status=0x1`, `gasUsed=21000` |
| second node | height in sync with node 1 (both at block 19) |
| ERC-20 deploy | `status=0x1`, `totalSupply()` = 1,000,000 |
| `make selftest` | all four checks pass |

## Known limitations

- Clique does not support shanghai/cancun block structures, so the chain is pure London: contracts must be compiled with `evmVersion: "london"`, otherwise `PUSH0` is an invalid opcode.
- No economic security. Development and internal validation only: no public RPC, no token fundraising.
- Windows native is untested — WSL recommended (tracked in #1).

## Install

```bash
git clone https://github.com/ugjdygh/aegis-private-chain.git
cd aegis-private-chain
make install && make account && make genesis && make init
make start          # separate terminal
make status && make selftest
```
