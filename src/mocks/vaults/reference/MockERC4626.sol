// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4626 } from "../../../interfaces/erc4626/IERC4626.sol";
import { MockERC20 } from "../../tokens/MockERC20.sol";

/// @notice Minimal ERC-4626 reference vault (OpenZeppelin-style rounding).
contract MockERC4626 is IERC4626 {
    MockERC20 public immutable assetToken;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    constructor(MockERC20 asset_) {
        assetToken = asset_;
    }

    function asset() external view returns (address) {
        return address(assetToken);
    }

    function totalAssets() public view returns (uint256) {
        return assetToken.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, false);
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, false);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, false);
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, true);
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, true);
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, false);
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return _convertToAssets(balanceOf[owner], false);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf[owner];
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        shares = _convertToShares(assets, false);
        assetToken.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
    }

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        assets = _convertToAssets(shares, true);
        assetToken.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        shares = _convertToShares(assets, true);
        if (msg.sender != owner) revert("not owner");
        _burn(owner, shares);
        assetToken.transfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        assets = _convertToAssets(shares, false);
        if (msg.sender != owner) revert("not owner");
        _burn(owner, shares);
        assetToken.transfer(receiver, assets);
    }

    function _convertToShares(uint256 assets, bool roundUp) internal view returns (uint256) {
        uint256 supply = totalSupply;
        if (supply == 0 || totalAssets() == 0) return assets;
        return roundUp ? _mulDivUp(assets, supply, totalAssets()) : (assets * supply) / totalAssets();
    }

    function _convertToAssets(uint256 shares, bool roundUp) internal view returns (uint256) {
        uint256 supply = totalSupply;
        if (supply == 0) return shares;
        return roundUp ? _mulDivUp(shares, totalAssets(), supply) : (shares * totalAssets()) / supply;
    }

    function _mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a * b + c - 1) / c;
    }

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}
