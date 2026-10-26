// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "../tokens/MockERC20.sol";
import {MockERC4626} from "./reference/MockERC4626.sol";
import {VulnerableVault} from "./vulnerable/VulnerableVault.sol";

/// @notice Executes an isolated inflation-attack comparison per call.
/// @dev Educational local-test tooling only; not for production use.
contract InflationScenarioActor {
    MockERC20 public immutable token;

    constructor(MockERC20 token_) {
        token = token_;
    }

    function depositReference(
        MockERC4626 vault,
        uint256 assets
    ) external returns (uint256) {
        require(token.approve(address(vault), assets), "reference approval failed");
        return vault.deposit(assets, address(this));
    }

    function depositVulnerable(
        VulnerableVault vault,
        uint256 assets
    ) external returns (uint256) {
        require(token.approve(address(vault), assets), "vulnerable approval failed");
        return vault.deposit(assets, address(this));
    }

    function donate(address vault, uint256 assets) external {
        require(token.transfer(vault, assets), "donation failed");
    }
}

contract InflationAttackScenario {
    event ScenarioCompleted(
        address indexed caller,
        address token,
        address referenceVault,
        address vulnerableVault,
        uint256 attackerDeposit,
        uint256 donation,
        uint256 victimDeposit,
        uint256 referenceVictimShares,
        uint256 vulnerableVictimShares,
        uint256 referenceAttackerShares,
        uint256 vulnerableAttackerShares,
        uint256 referenceTotalAssets,
        uint256 vulnerableTotalAssets
    );

    function runScenario(
        uint256 attackerDeposit,
        uint256 donation,
        uint256 victimDeposit
    ) external returns (
        uint256 referenceVictimShares,
        uint256 vulnerableVictimShares
    ) {
        require(attackerDeposit > 0, "Attacker deposit must be positive");
        require(victimDeposit > 0, "Victim deposit must be positive");

        MockERC20 token = new MockERC20();
        MockERC4626 referenceVault = new MockERC4626(token);
        VulnerableVault vulnerableVault =
            new VulnerableVault(address(token));

        InflationScenarioActor attacker =
            new InflationScenarioActor(token);
        InflationScenarioActor victim =
            new InflationScenarioActor(token);

        // Fund both independent scenarios.
        token.mint(address(attacker), 2 * (attackerDeposit + donation));
        token.mint(address(victim), 2 * victimDeposit);

        // Reference vault: attacker deposit, direct donation, victim deposit.
        attacker.depositReference(referenceVault, attackerDeposit);
        if (donation > 0) {
            attacker.donate(address(referenceVault), donation);
        }
        referenceVictimShares =
            victim.depositReference(referenceVault, victimDeposit);

        // Vulnerable vault: repeat the same sequence from a clean state.
        attacker.depositVulnerable(vulnerableVault, attackerDeposit);
        if (donation > 0) {
            attacker.donate(address(vulnerableVault), donation);
        }
        vulnerableVictimShares =
            victim.depositVulnerable(vulnerableVault, victimDeposit);

        emit ScenarioCompleted(
            msg.sender,
            address(token),
            address(referenceVault),
            address(vulnerableVault),
            attackerDeposit,
            donation,
            victimDeposit,
            referenceVictimShares,
            vulnerableVictimShares,
            referenceVault.balanceOf(address(attacker)),
            vulnerableVault.balanceOf(address(attacker)),
            referenceVault.totalAssets(),
            vulnerableVault.totalAssets()
        );
    }
}
