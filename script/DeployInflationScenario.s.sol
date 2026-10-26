// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {InflationAttackScenario} from "../src/mocks/vaults/InflationAttackScenario.sol";

contract DeployInflationScenario is Script {
    function run() external {
        vm.startBroadcast();
        InflationAttackScenario scenario = new InflationAttackScenario();
        vm.stopBroadcast();

        console2.log("InflationAttackScenario:", address(scenario));
    }
}
