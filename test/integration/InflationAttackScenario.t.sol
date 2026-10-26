// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {InflationAttackScenario} from "../../src/mocks/vaults/InflationAttackScenario.sol";

contract InflationAttackScenarioTest is Test {
    struct ScenarioEventData {
        address token;
        address referenceVault;
        address vulnerableVault;
        uint256 attackerDeposit;
        uint256 donation;
        uint256 victimDeposit;
        uint256 referenceVictimShares;
        uint256 vulnerableVictimShares;
        uint256 referenceAttackerShares;
        uint256 vulnerableAttackerShares;
        uint256 referenceTotalAssets;
        uint256 vulnerableTotalAssets;
    }

    function test_runScenarioReturnsAndEmitsAllocation() public {
        InflationAttackScenario scenario = new InflationAttackScenario();
        vm.recordLogs();

        (uint256 referenceShares, uint256 vulnerableShares) =
            scenario.runScenario(1e18, 1e18, 5e18);

        assertEq(referenceShares, 25e17);
        assertEq(vulnerableShares, 714285714285714285);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 signature = keccak256(
            "ScenarioCompleted(address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
        );
        bool found;
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].emitter != address(scenario) ||
                logs[i].topics.length == 0 || logs[i].topics[0] != signature) continue;

            ScenarioEventData memory data =
                abi.decode(logs[i].data, (ScenarioEventData));
            assertEq(data.attackerDeposit, 1e18);
            assertEq(data.donation, 1e18);
            assertEq(data.victimDeposit, 5e18);
            assertEq(data.referenceVictimShares, referenceShares);
            assertEq(data.vulnerableVictimShares, vulnerableShares);
            assertEq(data.referenceTotalAssets, 7e18);
            assertEq(data.vulnerableTotalAssets, 7e18);
            found = true;
            break;
        }
        assertTrue(found, "ScenarioCompleted event missing");
    }
}
