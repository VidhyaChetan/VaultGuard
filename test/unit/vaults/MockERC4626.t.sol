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
}