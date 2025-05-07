// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract Points is GeniDexBase {

    modifier onlyRewarder() {
        require(msg.sender == geniRewarder, "Only RewardDistributor can call");
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyOwner {
        geniRewarder = _rewarder;
    }

    function getTotalUnclaimedPoints() external view returns (uint256) {
        return totalUnclaimedPoints;
    }

    function getUserPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }

    function deductUserPoints(address user, uint256 pointsToDeduct) external onlyRewarder {
        require(userPoints[user] >= pointsToDeduct, "Not enough points");
        userPoints[user] -= pointsToDeduct;
        totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 6;
    }
}