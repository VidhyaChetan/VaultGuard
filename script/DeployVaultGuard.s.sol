
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MockERC20} from "../src/mocks/tokens/MockERC20.sol";
import {MockERC4626} from "../src/mocks/vaults/reference/MockERC4626.sol";
import {VulnerableVault} from "../src/mocks/vaults/vulnerable/VulnerableVault.sol";

contract DeployVaultGuard is Script {
    function run() external {
        vm.startBroadcast();

        MockERC20 token = new MockERC20();
        MockERC4626 referenceVault = new MockERC4626(token);
        VulnerableVault vulnerableVault =
            new VulnerableVault(address(token));

        vm.stopBroadcast();

        console2.log("MockERC20:", address(token));
        console2.log("MockERC4626:", address(referenceVault));
        console2.log("VulnerableVault:", address(vulnerableVault));
    }
}
