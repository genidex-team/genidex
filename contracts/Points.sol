// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract Points is GeniDexBase {

    event GeniRewarderUpdated(address indexed previous, address indexed newRewarder);

    modifier onlyRewarder() {
        require(msg.sender == geniRewarder, "Only RewardDistributor can call");
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyOwner {
        require(_rewarder != address(0), "rewarder = 0");
        emit GeniRewarderUpdated(geniRewarder, _rewarder);
        geniRewarder = _rewarder;
    }

    function getTotalUnclaimedPoints() external view returns (uint256) {
        return totalUnclaimedPoints;
    }

    function getUserPoints(address userAddress) external view returns (uint256) {
        uint80 userID = userIDs[userAddress];
        return userPoints[userID];
    }

    function deductUserPoints(address userAddress, uint256 pointsToDeduct) external onlyRewarder {
        uint80 userID = userIDs[userAddress];
        require(userPoints[userID] >= pointsToDeduct, "Not enough points");
        userPoints[userID] -= pointsToDeduct;
        totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 18;
    }
}