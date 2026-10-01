// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { IERC4626 } from "../../../interfaces/erc4626/IERC4626.sol";
import { ERC4626Handler } from "../../../fuzz/handlers/erc4626/ERC4626Handler.sol";
import { MockERC20 } from "../../../mocks/tokens/MockERC20.sol";

/// @title ERC4626InvariantTest
/// @notice Inherit, call configureInvariantTest(vault, asset) in setUp().
abstract contract ERC4626InvariantTest is StdInvariant {
    IERC4626 internal vault;
    MockERC20 internal asset;
    ERC4626Handler internal handler;

    function configureInvariantTest(IERC4626 vault_, MockERC20 asset_) internal {
        vault = vault_;
        asset = asset_;
        handler = new ERC4626Handler(vault_, asset_);
        targetContract(address(handler));
    }

    function invariant_vaultBalanceMatchesTotalAssets() public view {
        require(vault.totalAssets() == asset.balanceOf(address(vault)), "totalAssets != balance");
    }

    function invariant_actorsSharesLteTotalSupply() public view {
        uint256 sum;
        for (uint256 i; i < handler.ACTOR_COUNT(); ++i) {
            sum += vault.balanceOf(handler.actors(i));
        }
        require(sum <= vault.totalSupply(), "shares sum > totalSupply");
    }

    function invariant_donationsIncreaseOrPreserveTotalAssets() public view {
        require(handler.ghost_donations() == 0 || vault.totalAssets() > 0, "empty after donation");
    }

    function invariant_convertRoundTripShares(uint256 shares) public view {
        shares = bound(shares, 0, vault.totalSupply());
        if (shares == 0) return;
        uint256 assets = vault.convertToAssets(shares);
        uint256 back = vault.convertToShares(assets);
        require(back <= shares, "convert round-trip favors user");
    }
}
