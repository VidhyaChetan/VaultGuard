// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { IERC4626 } from "../../../src/interfaces/erc4626/IERC4626.sol";
import { ERC4626InvariantTest } from "../../../src/core/invariants/erc4626/ERC4626InvariantTest.sol";
import { MockERC20 } from "../../../src/mocks/tokens/MockERC20.sol";
import { MockERC4626 } from "../../../src/mocks/vaults/reference/MockERC4626.sol";

contract VaultInvariantsTest is ERC4626InvariantTest, Test {
    function setUp() public {
        asset = new MockERC20();
        vault = IERC4626(address(new MockERC4626(asset)));
        configureInvariantTest(vault, asset);
    }
}
