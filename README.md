# VaultGuard

**Stateful invariant and differential security testing for ERC-4626 vaults using Foundry.**

VaultGuard is an educational security-testing project built around the ERC-4626 tokenized vault standard.

It combines:

- Foundry unit testing
- stateful fuzzing and invariant testing
- multi-actor handlers
- ERC-4626 preview/conversion properties
- adversarial vault behavior
- differential testing between a reference implementation and a vulnerable implementation
- a local React dashboard for exploring vault state, Foundry results, and the inflation scenario

The goal is to demonstrate how ERC-4626 security properties can be expressed as executable tests and how seemingly small accounting decisions can create serious share-allocation vulnerabilities.

---

## What VaultGuard demonstrates

The project contains two vault implementations:

- **MockERC4626** — a reference implementation used to exercise ERC-4626 conversion, preview, limit, and rounding behavior.
- **VulnerableVault** — an intentionally vulnerable implementation demonstrating an ERC-4626 inflation/donation attack.

The same attack sequence can therefore be executed against both implementations and compared through tests.

### Differential inflation test

The integration test uses the same sequence against both vaults:

1. Attacker deposits `1 ETH`
2. Attacker donates `1 ETH`
3. Victim deposits `5 ETH`

The resulting share allocation differs substantially.

| Implementation | Victim shares |
|---|---:|
| Reference vault | `2.5 ETH` worth of shares |
| Vulnerable vault | `0.714285714285714285` shares |

The differential test demonstrates that the vulnerable implementation calculates the victim's shares using the vault's **post-deposit asset balance**, causing the victim's allocation to be diluted.

### Extreme inflation case

A focused unit test demonstrates an even more severe outcome:

1. Attacker deposits `1 wei`
2. Attacker donates `5 ETH`
3. Victim deposits `5 ETH`

The victim receives **0 shares**, while the attacker retains the only share.

This test provides a concrete executable demonstration of the inflation attack rather than merely identifying the code pattern as potentially vulnerable.

---

## Testing architecture

VaultGuard uses multiple testing layers.

### 1. Unit tests

Focused tests verify individual ERC-4626 behaviors, including:

- `previewDeposit`
- `previewMint`
- `previewWithdraw`
- `previewRedeem`
- conversion rounding
- maximum deposit/mint/redeem/withdraw limits
- donation/share allocation behavior
- inflation attack behavior

### 2. Stateful invariant testing

`ERC4626Handler` provides multiple actors and state-changing operations to exercise the vault through randomized sequences.

The handler supports:

- deposits
- mints
- withdrawals
- redemptions
- donations

The invariant suite checks properties such as:

- vault token balance matches reported total assets
- actor share balances do not exceed total supply
- donations do not decrease total assets
- share conversion round-trips remain consistent

The invariant campaign uses **256 runs with 128,000 generated calls**.

### 3. Differential testing

The reference and vulnerable vaults are subjected to the same inflation sequence.

This makes the security impact directly observable rather than relying only on inspection of the vulnerable implementation.

---

## Project structure

```text
VaultGuard/
├── foundry.toml
├── remappings.txt
├── frontend/             # React/Vite dashboard and setup guide
├── src/
│   ├── interfaces/erc4626/
│   │   └── IERC4626.sol
│   ├── core/invariants/erc4626/
│   │   └── ERC4626InvariantTest.sol
│   ├── fuzz/handlers/erc4626/
│   │   └── ERC4626Handler.sol
│   └── mocks/
│       ├── tokens/
│       │   └── MockERC20.sol
│       └── vaults/
│           ├── reference/
│           │   └── MockERC4626.sol
│           └── vulnerable/
│               └── VulnerableVault.sol
└── test/
    ├── integration/
    │   └── InflationAttackComparison.t.sol
    └── unit/
        └── vaults/
            ├── MockERC4626.t.sol
            └── VulnerableVault.t.sol
```

The stateful fuzzing handler is located at:

```text
src/fuzz/handlers/erc4626/ERC4626Handler.sol
```

---

## Invariant architecture

The invariant harness follows a handler-driven Foundry model:

```text
ERC4626InvariantTest
        │
        ▼
ERC4626Handler
        │
        ├── deposit
        ├── mint
        ├── withdraw
        ├── redeem
        └── donate
        │
        ▼
   ERC-4626 Vault
        │
        ▼
   Invariant checks
```

Multiple actors are used so that the fuzz campaign exercises interactions between different users rather than repeatedly testing a single account.

---

## Key security properties

### Accounting consistency

The vault's reported asset balance should remain consistent with the underlying ERC-20 balance held by the vault.

### Preview/actual consistency

ERC-4626 preview functions are tested against the corresponding state-changing operations, with the expected rounding direction taken into account.

### Conversion consistency

Asset/share conversions are exercised in round-trip relationships to detect inconsistent conversion behavior.

### Donation behavior

Direct asset donations can change the vault's asset/share ratio without increasing total share supply. Tests therefore track asset balances before and after donations.

### Inflation resistance

The project explicitly tests first-depositor and donation-based inflation scenarios.

---

## Running the project

Install Foundry and Node.js, clone the repository, and initialize the test dependency:

```bash
git submodule update --init --recursive
forge test
```

To run the dashboard with live contract data, keep these processes open in separate terminals:

```bash
# Terminal 1: local blockchain
anvil
```

```bash
# Terminal 2: frontend
cd frontend
npm install
npm run dev
```

Open the **Local** URL printed by Vite (usually `http://localhost:5173`). Port `8545` is Anvil's RPC endpoint, not the dashboard.

From the repository root, deploy the token and both vaults to the running Anvil node. First set `ANVIL_PRIVATE_KEY` to a development private key printed by Anvil. After deploying the token, set `TOKEN_ADDRESS` to its `Deployed to` address. Keep `--constructor-args` at the end of the vault commands, after all other options:

```bash
export ANVIL_PRIVATE_KEY='0xPASTE_ANVIL_DEVELOPMENT_KEY'
forge create src/mocks/tokens/MockERC20.sol:MockERC20 --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast
export TOKEN_ADDRESS='0xPASTE_TOKEN_DEPLOYED_TO_ADDRESS'
forge create src/mocks/vaults/reference/MockERC4626.sol:MockERC4626 --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast --constructor-args "$TOKEN_ADDRESS"
forge create src/mocks/vaults/vulnerable/VulnerableVault.sol:VulnerableVault --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast --constructor-args "$TOKEN_ADDRESS"
```

Enter the three resulting addresses in **Environment**, save them, and click **Check connection**. A new Anvil process starts a fresh chain, so redeploy and update the addresses after a restart. For wallet transactions, connect a browser wallet to `http://127.0.0.1:8545` on chain ID `31337` with a funded Anvil development account.

To view test results in the dashboard, run this from the repository root, then import `frontend/forge-results.json` on the **Security Tests** page:

```bash
forge test --json > frontend/forge-results.json
```

The **Vulnerability Lab** is a deterministic local calculation of the contracts' share formulas, not an on-chain transaction. The **Transaction History** page scans direct calls to the configured contracts in the latest 200 blocks. See [frontend/README.md](frontend/README.md) for the full frontend guide.

Run individual test groups with:

```bash
forge test --match-contract MockERC4626Test -vv
```

```bash
forge test --match-contract VulnerableVaultTest -vv
```

```bash
forge test --match-contract InflationAttackComparisonTest -vv
```

```bash
forge test --match-contract VaultInvariantsTest -vv
```

---

## Current test results

The current suite passes:

```text
15 tests passed
0 failed
0 skipped
```

The invariant suite additionally executes:

```text
256 invariant runs
128,000 generated calls
4 invariants passed
```

The fuzz handler exercises deposits, mints, withdrawals, redemptions, and donations across multiple actors.

---

## Skills demonstrated

VaultGuard demonstrates practical experience with:

| Skill | Evidence |
|---|---|
| **Foundry invariant testing** | `StdInvariant`, handler architecture, `targetContract` |
| **ERC-4626 security analysis** | Preview functions, conversions, limits, rounding |
| **Adversarial testing** | `VulnerableVault` and focused inflation attack tests |
| **Stateful fuzzing** | Multi-actor handler and randomized action sequences |
| **Differential testing** | Same attack sequence compared across two implementations |
| **Security-oriented test design** | Vulnerabilities demonstrated through executable assertions |
| **Teaching through code** | Reference implementation contrasted with intentionally vulnerable behavior |

---

## Security scope

VaultGuard is an educational security-testing project and is **not a complete ERC-4626 audit framework**.

The reference vault is intended to provide a controlled implementation for testing and comparison. Passing the included tests does not establish that an arbitrary production vault is secure.

The project currently focuses on:

- accounting consistency
- conversion and preview behavior
- rounding
- vault limits
- donations
- inflation attack behavior
- stateful interactions between multiple actors

Production vaults may contain additional risks involving fees, strategies, external protocols, access control, upgradeability, oracle dependencies, asynchronous assets, or other protocol-specific behavior.

---

## Provenance

VaultGuard began from an existing ERC-4626 invariant-testing codebase that was available locally during development.

The inherited material provided the initial structure for ERC-4626 interfaces, invariant testing, stateful fuzzing handlers, reference and vulnerable vault mocks, and Foundry test organization.

The current project has been substantially modified and extended beyond that starting point.

The original repository history is preserved in Git where available. Existing source files are not presented as having been originally authored by the current project maintainer.

See [`docs/PROVENANCE.md`](docs/PROVENANCE.md) for the detailed provenance and repository-cleanup record.

See [`docs/STRUCTURE.md`](docs/STRUCTURE.md) for the directory structure and architectural layout.

---

## Development philosophy

VaultGuard distinguishes between:

1. inherited starting material,
2. modifications to inherited code,
3. newly authored tests and framework components, and
4. security findings demonstrated by executable tests.

The project emphasizes **reproducible security claims**.

Rather than only identifying a vulnerability pattern in source code, the project attempts to demonstrate its effect through focused tests, stateful fuzzing, and differential comparisons.

---

## Possible extensions

Potential future work includes:

- handler coverage for additional ERC-4626 limit functions
- fee-bearing vault implementations
- strategy-backed vault models
- additional donation and share-accounting properties
- cross-contract asset-transfer scenarios
- expanded differential testing against additional implementations

---

## License

MIT
