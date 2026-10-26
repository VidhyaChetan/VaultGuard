# VaultGuard frontend

A React/Vite interface for the Foundry ERC-4626 security lab. The app includes an overview, live vault explorer, wallet operations, Foundry report viewer, inflation comparison, recent transaction scanner, and local environment configuration.

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
2. Deploy `MockERC20`, then deploy `MockERC4626` and `VulnerableVault` with the token address as their constructor argument. Run these from the repository root. Replace the two quoted placeholder values after `export` with a development key printed by Anvil and the token's `Deployed to` address:

   ```bash
   export ANVIL_PRIVATE_KEY='0xPASTE_ANVIL_DEVELOPMENT_KEY'
   forge create src/mocks/tokens/MockERC20.sol:MockERC20 --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast
   export TOKEN_ADDRESS='0xPASTE_TOKEN_DEPLOYED_TO_ADDRESS'
   forge create src/mocks/vaults/reference/MockERC4626.sol:MockERC4626 --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast --constructor-args "$TOKEN_ADDRESS"
   forge create src/mocks/vaults/vulnerable/VulnerableVault.sol:VulnerableVault --rpc-url http://127.0.0.1:8545 --private-key "$ANVIL_PRIVATE_KEY" --broadcast --constructor-args "$TOKEN_ADDRESS"
   ```

3. In **Environment**, enter the three deployed addresses and click **Save configuration**, then **Check connection**. Addresses are stored in browser local storage. The frontend deliberately does not assume the uploaded app's old Anvil addresses remain valid.
4. To make transactions, connect a browser wallet set to RPC `http://127.0.0.1:8545`, chain ID `31337`, with a funded local account. Use only Anvil's development keys for this local environment.

The vault explorer verifies bytecode and matching asset addresses before enabling actions. Mint, approve, and deposit call the repository's current contracts. It does not assume vault events exist.

## Import test results

From the repository root:

```bash
forge test --json > frontend/forge-results.json
```

Open **Security Tests** and import the generated file. The report is held in the current browser session; it is not uploaded or automatically regenerated. Foundry output format may vary by version; the viewer expects suites with `test_results` objects.

## Scope

The vulnerability lab evaluates the same integer share formulas used in the repository's reference and vulnerable contracts. It is a deterministic local model, not an on-chain transaction. Run `forge test --match-contract InflationAttackComparisonTest -vv` to execute the differential test.

History scans direct transactions addressed to the three configured contracts in the most recent 200 blocks. Internal calls and transactions outside that range are not shown. This is an educational security testing interface, not an audit certificate.
