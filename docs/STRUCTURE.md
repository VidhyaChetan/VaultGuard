# Project Structure

VaultGuard uses a layered Foundry architecture that separates interfaces, invariant logic, stateful fuzzing, mock implementations, and executable tests.

## Directory tree

```text
forge-4626-invariants/
├── foundry.toml
├── remappings.txt
├── src/
│   ├── interfaces/
│   │   └── erc4626/
│   │       └── IERC4626.sol
│   │
│   ├── core/
│   │   └── invariants/
│   │       └── erc4626/
│   │           └── ERC4626InvariantTest.sol
│   │
│   ├── fuzz/
│   │   └── handlers/
│   │       └── erc4626/
│   │           └── ERC4626Handler.sol
│   │
│   └── mocks/
│       ├── tokens/
│       │   └── MockERC20.sol
│       │
│       └── vaults/
│           ├── reference/
│           │   └── MockERC4626.sol
│           │
│           └── vulnerable/
│               └── VulnerableVault.sol
│
├── test/
│   ├── integration/
│   │   ├── InflationAttackComparison.t.sol
│   │   └── invariants/
│   │       └── VaultInvariants.t.sol
│   │
│   └── unit/
│       └── vaults/
│           ├── MockERC4626.t.sol
│           └── VulnerableVault.t.sol
│
└── docs/
    ├── PROVENANCE.md
    └── STRUCTURE.md
```

## Source architecture

### `src/interfaces/erc4626/`

Contains the ERC-4626 interface used by the project.

```text
IERC4626.sol
```

The interface defines the vault-facing API used by the testing infrastructure.

---

### `src/core/invariants/erc4626/`

Contains the reusable invariant-test foundation.

```text
ERC4626InvariantTest.sol
```

This base suite configures the stateful fuzzing environment and defines the high-level properties checked against an ERC-4626 vault.

The concrete invariant test is located under:

```text
test/integration/invariants/VaultInvariants.t.sol
```

---

### `src/fuzz/handlers/erc4626/`

Contains the stateful fuzzing handler:

```text
ERC4626Handler.sol
```

The handler provides multiple actors and exposes state-changing operations to Foundry's invariant engine.

Current actions include:

- `deposit`
- `mint`
- `withdraw`
- `redeem`
- `donate`

The handler also tracks ghost state used to reason about actions and asset movements during fuzzing.

### Why use a handler?

Directly fuzzing individual functions does not reproduce the variety of state transitions that can occur in a live vault.

The handler allows Foundry to generate sequences such as:

```text
deposit → donate → deposit → redeem → mint → withdraw → ...
```

across multiple actors.

This makes the invariant suite stateful rather than a collection of isolated function tests.

---

## Mock implementations

### `src/mocks/tokens/`

Contains:

```text
MockERC20.sol
```

This provides the controlled ERC-20 asset used by the vault implementations and tests.

---

### `src/mocks/vaults/reference/`

Contains:

```text
MockERC4626.sol
```

This is the project's reference vault implementation.

It is used to exercise:

- asset/share conversions,
- preview functions,
- rounding behavior,
- maximum limits,
- deposits,
- mints,
- withdrawals,
- redemptions, and
- donation/share allocation behavior.

It serves as a controlled comparison point for the intentionally vulnerable implementation.

---

### `src/mocks/vaults/vulnerable/`

Contains:

```text
VulnerableVault.sol
```

This implementation intentionally contains an inflation-vulnerability pattern.

The vulnerable `deposit` flow transfers the assets into the vault before measuring the vault balance used for share calculation.

The resulting post-transfer balance can therefore affect the number of shares issued to the depositor.

The vulnerability is demonstrated through executable tests rather than being included merely as a theoretical example.

---

## Test architecture

### Unit tests

Located under:

```text
test/unit/vaults/
```

These tests isolate specific behaviors.

#### `MockERC4626.t.sol`

Covers reference-vault properties including:

- deposit preview behavior,
- mint preview behavior,
- withdraw preview behavior,
- redeem preview behavior,
- rounding,
- maximum limits,
- donation/share allocation.

#### `VulnerableVault.t.sol`

Contains the focused inflation attack demonstration.

The test uses an extreme first-depositor scenario to demonstrate that the victim can receive zero shares.

---

## Integration tests

Located under:

```text
test/integration/
```

### `InflationAttackComparison.t.sol`

This test executes the same attack sequence against both the reference and vulnerable implementations.

The sequence is:

```text
Attacker deposits 1 ETH
        ↓
Attacker donates 1 ETH
        ↓
Victim deposits 5 ETH
        ↓
Compare resulting share allocation
```

The purpose is to make the security impact visible through differential testing.

---

## Invariant tests

Located under:

```text
test/integration/invariants/
```

### `VaultInvariants.t.sol`

This is the concrete Foundry invariant test.

It deploys the reference vault and configures the shared `ERC4626InvariantTest` harness with:

- the vault,
- the underlying asset, and
- the stateful handler.

The invariant engine then generates randomized sequences of handler actions.

Current invariant properties include:

- vault balance matches reported total assets,
- actor shares do not exceed total supply,
- donations increase or preserve total assets, and
- share conversion round-trips remain consistent.

---

## Testing layers

The project can therefore be viewed as four connected layers:
```text
                 ┌─────────────────────────┐
                 │       Test Suites       │
                 │ unit / integration /    │
                 │ invariant tests         │
                 └────────────┬────────────┘
                              │
                 ┌────────────▼────────────┐
                 │   Testing Infrastructure│
                 │ invariant harness +     │
                 │ stateful handler        │
                 └────────────┬────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
     ┌────────▼────────┐             ┌────────▼────────┐
     │ Reference Vault │             │ Vulnerable Vault│
     │ MockERC4626     │             │ VulnerableVault │
     └────────┬────────┘             └────────┬────────┘
              │                               │
              └───────────────┬───────────────┘
                              │
                    ┌─────────▼─────────┐
                    │    MockERC20      │
                    │ underlying asset  │
                    └───────────────────┘
```
## Deepest source path

The deepest source path in the current architecture is:

```text
src/fuzz/handlers/erc4626/ERC4626Handler.sol
```

This path reflects the deliberately layered organization:

```text
src
└── fuzz
    └── handlers
        └── erc4626
            └── ERC4626Handler.sol
```

The depth is a consequence of separating fuzzing infrastructure by responsibility and standard rather than placing all testing logic into a single directory.

## Design principle

The project keeps **implementation**, **testing infrastructure**, and **test cases** separate.

This makes it possible to:

1. reuse the invariant harness,
2. change the vault implementation under test,
3. exercise it through the same stateful handler,
4. compare different implementations under identical scenarios, and
5. keep focused vulnerability demonstrations separate from general invariants.