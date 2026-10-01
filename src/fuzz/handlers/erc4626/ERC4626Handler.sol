// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4626 } from "../../../interfaces/erc4626/IERC4626.sol";
import { MockERC20 } from "../../../mocks/tokens/MockERC20.sol";

/// @notice Fuzz handler: bounded random ERC-4626 actions across N actors.
contract ERC4626Handler {
    IERC4626 public immutable vault;
    MockERC20 public immutable asset;

    address[] public actors;
    uint256 public constant MAX_ASSETS = 1e24;
    uint256 public constant ACTOR_COUNT = 4;

    uint256 public ghost_totalDeposited;
    uint256 public ghost_totalWithdrawn;
    uint256 public ghost_donations;

    constructor(IERC4626 vault_, MockERC20 asset_) {
        vault = vault_;
        asset = asset_;
        for (uint256 i; i < ACTOR_COUNT; ++i) {
            address actor = address(uint160(0xA000 + i));
            actors.push(actor);
            asset.mint(actor, 1e30);
            vm.prank(actor);
            asset.approve(address(vault), type(uint256).max);
        }
    }

    function deposit(uint256 assets, uint256 actorSeed) external {
        assets = bound(assets, 1, MAX_ASSETS);
        address actor = actors[actorSeed % ACTOR_COUNT];
        vm.prank(actor);
        uint256 shares = vault.deposit(assets, actor);
        ghost_totalDeposited += assets;
        require(shares > 0, "zero shares");
    }

    function withdraw(uint256 assets, uint256 actorSeed) external {
        address actor = actors[actorSeed % ACTOR_COUNT];
        uint256 maxW = vault.maxWithdraw(actor);
        if (maxW == 0) return;
        assets = bound(assets, 1, maxW);
        vm.prank(actor);
        vault.withdraw(assets, actor, actor);
        ghost_totalWithdrawn += assets;
    }

    function donate(uint256 amount, uint256 actorSeed) external {
        amount = bound(amount, 1, MAX_ASSETS / 10);
        address actor = actors[actorSeed % ACTOR_COUNT];
        vm.prank(actor);
        asset.transfer(address(vault), amount);
        ghost_donations += amount;
    }

    function bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        if (x < min) return min;
        if (x > max) return max;
        return x;
    }

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code"))));

    interface Vm {
        function prank(address) external;
    }
}
