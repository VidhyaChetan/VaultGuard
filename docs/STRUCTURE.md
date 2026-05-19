# Directory structure

```
forge-4626-invariants/
├── foundry.toml
├── remappings.txt
├── src/
│   ├── interfaces/erc4626/           # IERC4626
│   ├── core/invariants/erc4626/      # ERC4626InvariantTest (base suite)
│   ├── fuzz/handlers/erc4626/        # ERC4626Handler (5 levels deep)
│   └── mocks/
│       ├── tokens/                   # MockERC20
│       └── vaults/
│           ├── reference/            # MockERC4626 (correct rounding)
│           └── vulnerable/           # VulnerableVault (attack demo)
└── test/
    ├── integration/invariants/       # fuzz invariant run
    └── unit/vaults/                    # inflation unit test
```

**Deepest path:** `src/fuzz/handlers/erc4626/ERC4626Handler.sol`
