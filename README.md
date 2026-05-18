# forge-4626-invariants

**Drop-in Foundry invariant tests for ERC-4626 vaults** (layered layout).

```bash
git clone https://github.com/sr-werney/forge-4626-invariants.git
cd forge-4626-invariants
forge install foundry-rs/forge-std
forge test
```

## Structure (4–5 levels)

See **[docs/STRUCTURE.md](docs/STRUCTURE.md)**.

```
src/core/invariants/erc4626/     → base invariant suite
src/fuzz/handlers/erc4626/       → deposit / withdraw / donate handler
src/mocks/vaults/reference/      → compliant vault
src/mocks/vaults/vulnerable/     → inflation attack demo
```

```solidity
import { ERC4626InvariantTest } from "forge-4626-invariants/core/invariants/erc4626/ERC4626InvariantTest.sol";
```

MIT
