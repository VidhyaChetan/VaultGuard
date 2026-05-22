// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Naive vault — vulnerable to first-depositor inflation via direct donation.
/// @dev Educational only. See test/unit/vaults/VulnerableVault.t.sol
contract VulnerableVault {
    IERC20 public immutable asset;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function totalAssets() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        asset.transferFrom(msg.sender, address(this), assets);
        uint256 supply = totalSupply;
        uint256 bal = asset.balanceOf(address(this));
        shares = supply == 0 ? assets : (assets * supply) / bal;
        balanceOf[receiver] += shares;
        totalSupply += shares;
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        uint256 supply = totalSupply;
        uint256 bal = asset.balanceOf(address(this));
        if (supply == 0 || bal == 0) return assets;
        return (assets * supply) / bal;
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
