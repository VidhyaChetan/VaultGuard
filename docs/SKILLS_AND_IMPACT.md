# Skills & impact — forge-4626-invariants

## What problem this solves

ERC-4626 vaults share the same invariant surface. Teams rewrite tests; audits miss donation paths and inflation attacks. This library encodes **known-good patterns** once.

## Skills you demonstrate

| Skill | Evidence in this repo |
|-------|------------------------|
| **Foundry invariant testing** | `StdInvariant`, handler, `targetContract` |
| **ERC-4626 standard depth** | Preview vs actual, convert round-trips |
| **Adversarial thinking** | `VulnerableVault` + `VulnerableVaultTest` |
| **Fuzz discipline** | Bounded assets, multi-actor handler |
| **Teaching through code** | Reference `MockERC4626` vs naive vault |

## Invariant map (interview-ready)

| Invariant | Catches |
|-----------|---------|
| `vaultBalanceMatchesTotalAssets` | Accounting drift vs token balance |
| `previewDepositGeActualShares` | User-favorable rounding bugs |
| `convertRoundTripShares` | Share/asset conversion errors |
| Inflation test | First depositor + donation attacks |

## Meaningful next contributions

1. Handler calls for `maxDeposit` / `maxWithdraw` / `maxRedeem`  
2. Fee-bearing vault extension  
3. Invariant: internal transfer between strategy contracts  

## Who should care

- Vault protocol engineers pre-audit  
- Security firms standardizing 4626 engagements  
- Foundry educators  
