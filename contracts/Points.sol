// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract Points is GeniDexBase {

    event GeniRewarderUpdated(address indexed previous, address indexed newRewarder);

    modifier onlyRewarder() {
        if (msg.sender != geniRewarder) {
            revert Helper.OnlyRewarderAllowed(msg.sender);
        }
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyOwner {
        if (_rewarder == address(0)) {
            revert Helper.InvalidAddress();
        }
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

        uint256 available = userPoints[userID];
        if (available < pointsToDeduct) {
            revert Helper.InsufficientPoints(available, pointsToDeduct);
        }
        userPoints[userID] -= pointsToDeduct;
        totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 8;
    }
}