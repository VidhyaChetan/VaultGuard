// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "../../../src/mocks/tokens/MockERC20.sol";
import { MockERC4626 } from "../../../src/mocks/vaults/reference/MockERC4626.sol";

contract MockERC4626Test is Test {
    MockERC20 internal asset;
    MockERC4626 internal vault;

    address internal user = address(0x1);

    function setUp() public {
        asset = new MockERC20();
        vault = new MockERC4626(asset);

        asset.mint(user, 1_000 ether);

        vm.prank(user);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_previewDepositDoesNotOverstateShares() public {
        uint256 assets = 100 ether;

        uint256 previewed = vault.previewDeposit(assets);

        vm.prank(user);
        uint256 received = vault.deposit(assets, user);

        assertLe(previewed, received);
    }

    function test_mintDoesNotChargeLessThanPreview() public {
        uint256 shares = 100 ether;

        uint256 previewedAssets = vault.previewMint(shares);

        uint256 balanceBefore = asset.balanceOf(user);

        vm.prank(user);
        uint256 chargedAssets = vault.mint(shares, user);

        uint256 balanceAfter = asset.balanceOf(user);

        assertEq(chargedAssets, previewedAssets);
        assertEq(balanceBefore - balanceAfter, chargedAssets);
        assertEq(vault.balanceOf(user), shares);
    }

    function test_previewMintRoundsUpForFractionalAssets() public {
        vm.prank(user);
        vault.deposit(3, user);

        vm.prank(user);
        asset.transfer(address(vault), 1);

        // Vault now has 4 assets backing 3 shares.
        // Minting 1 share requires ceil(1 * 4 / 3) = 2 assets.
        uint256 shares = 1;

        uint256 previewedAssets = vault.previewMint(shares);

        assertEq(previewedAssets, 2);

        vm.prank(user);
        uint256 chargedAssets = vault.mint(shares, user);

        assertEq(chargedAssets, 2);
        assertEq(vault.balanceOf(user), 4);
    }

    function test_redeemDoesNotReturnLessThanPreview() public {
        uint256 depositAssets = 100 ether;

        vm.prank(user);
        uint256 mintedShares = vault.deposit(depositAssets, user);

        uint256 previewedAssets = vault.previewRedeem(mintedShares);

        uint256 balanceBefore = asset.balanceOf(user);

        vm.prank(user);
        uint256 redeemedAssets = vault.redeem(mintedShares, user, user);

        uint256 balanceAfter = asset.balanceOf(user);

        assertEq(redeemedAssets, previewedAssets);
        assertEq(balanceAfter - balanceBefore, redeemedAssets);
        assertEq(vault.balanceOf(user), 0);
    }
    function test_previewRedeemRoundsDownForFractionalAssets() public {
        vm.prank(user);
        vault.deposit(3, user);

        vm.prank(user);
        asset.transfer(address(vault), 1);

        // Vault now has 4 assets backing 3 shares.
        // Redeeming 1 share gives floor(1 * 4 / 3) = 1 asset.
        uint256 shares = 1;

        uint256 previewedAssets = vault.previewRedeem(shares);

        assertEq(previewedAssets, 1);

        uint256 balanceBefore = asset.balanceOf(user);

        vm.prank(user);
        uint256 redeemedAssets = vault.redeem(shares, user, user);

        assertEq(redeemedAssets, 1);
        assertEq(asset.balanceOf(user), balanceBefore + 1);
        assertEq(vault.balanceOf(user), 2);
    }
    function test_withdrawDoesNotBurnMoreThanPreview() public {
        uint256 depositAssets = 100 ether;

        vm.prank(user);
        vault.deposit(depositAssets, user);

        uint256 withdrawAssets = 40 ether;
        uint256 previewedShares = vault.previewWithdraw(withdrawAssets);

        uint256 sharesBefore = vault.balanceOf(user);
        uint256 balanceBefore = asset.balanceOf(user);

        vm.prank(user);
        uint256 burnedShares = vault.withdraw(
            withdrawAssets,
            user,
            user
        );

        uint256 sharesAfter = vault.balanceOf(user);
        uint256 balanceAfter = asset.balanceOf(user);

        assertEq(burnedShares, previewedShares);
        assertEq(sharesBefore - sharesAfter, burnedShares);
        assertEq(balanceAfter - balanceBefore, withdrawAssets);
    }
    function test_previewWithdrawRoundsUpForFractionalShares() public {
        vm.prank(user);
        vault.deposit(3, user);

        vm.prank(user);
        asset.transfer(address(vault), 1);

        // Vault now has 4 assets backing 3 shares.
        // Withdrawing 1 asset requires ceil(1 * 3 / 4) = 1 share.
        uint256 withdrawAssets = 1;

        uint256 previewedShares = vault.previewWithdraw(withdrawAssets);

        assertEq(previewedShares, 1);

        uint256 sharesBefore = vault.balanceOf(user);

        vm.prank(user);
        uint256 burnedShares = vault.withdraw(
            withdrawAssets,
            user,
            user
        );

        assertEq(burnedShares, 1);
        assertEq(sharesBefore - vault.balanceOf(user), 1);
    }
    function test_maxDepositAllowsMaximumUint256() public view {
        uint256 maxDeposit = vault.maxDeposit(user);

        assertEq(maxDeposit, type(uint256).max);
    }
}