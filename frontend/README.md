# VaultGuard frontend

A React/Vite interface for the Foundry ERC-4626 security lab. The app includes an overview, live vault explorer, wallet operations, Foundry report viewer, local and on-chain inflation comparisons, recent transaction scanner, and local environment configuration.

## Run

From the repository root:

```bash
cd frontend
npm install
npm run dev
```

Open the URL printed by Vite. Run `npm run build` for a production bundle.

## Connect to local contracts

1. Start `anvil` in another terminal.
2. From the repository root, use a development private key printed by Anvil to run both deployment scripts:

   ```bash
   export ANVIL_PRIVATE_KEY='0xPASTE_ANVIL_DEVELOPMENT_KEY'
   forge script script/DeployVaultGuard.s.sol:DeployVaultGuard --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast
   forge script script/DeployInflationScenario.s.sol:DeployInflationScenario --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast
   ```

   Copy the four logged addresses: token, reference vault, vulnerable vault, and inflation scenario. The scenario contract creates fresh isolated vaults during each run, separately from the explorer's three contracts.

3. In **Environment**, enter the addresses and click **Save configuration**, then **Check connection**. The three explorer contracts are verified immediately; the optional scenario address is checked when you run it. Addresses are stored in browser local storage and must be updated after an Anvil reset.
4. To make transactions, connect a browser wallet set to RPC `http://127.0.0.1:8545`, chain ID `31337`, with a funded local account. Use only Anvil's development keys for this local environment.

The vault explorer verifies bytecode and matching asset addresses before enabling actions. Mint, approve, and deposit call the repository's current contracts. It does not assume vault events exist.

## Import test results

From the repository root, run:

```bash
./scripts/test-with-report.sh
```

Open **Security Tests** and import `frontend/forge-results.json`. The helper keeps the prior report if Forge fails to produce valid JSON and returns Forge's exit status. The report is held in the current browser session; it is not uploaded or automatically regenerated. Foundry output format may vary by version; the viewer expects suites with `test_results` objects.

## Scope

The vulnerability lab offers a deterministic local model and, when the scenario contract and an Anvil wallet are configured, a real transaction. The on-chain run reads `ScenarioCompleted` from the confirmed receipt. Run `forge test --match-contract InflationAttackComparisonTest -vv` to execute the separate Foundry differential test.

History scans direct transactions addressed to the configured token, vaults, and scenario contract in the most recent 200 blocks. Internal calls and transactions outside that range are not shown. This is an educational security testing interface, not an audit certificate.
