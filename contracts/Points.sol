// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract Points is GeniDexBase {

    event GeniRewarderUpdated(address indexed previous, address indexed newRewarder);

    modifier onlyRewarder() {
        Storage.UserData storage u = Storage.user();
        if (msg.sender != u.geniRewarder) {
            revert Helper.OnlyRewarderAllowed(msg.sender);
        }
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyRole(OPERATOR_ROLE) {
        Storage.UserData storage u = Storage.user();
        if (_rewarder == address(0)) {
            revert Helper.InvalidAddress();
        }
        emit GeniRewarderUpdated(u.geniRewarder, _rewarder);
        u.geniRewarder = _rewarder;
    }

    function getTotalUnclaimedPoints() external view returns (uint256) {
        Storage.UserData storage u = Storage.user();
        return u.totalUnclaimedPoints;
    }

    function getUserPoints(address userAddress) external view returns (uint256) {
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[userAddress];
        return u.userPoints[userID];
    }

    function deductUserPoints(address userAddress, uint256 pointsToDeduct) external onlyRewarder {
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[userAddress];

        uint256 available = u.userPoints[userID];
        if (available < pointsToDeduct) {
            revert Helper.InsufficientPoints(available, pointsToDeduct);
        }
        u.userPoints[userID] -= pointsToDeduct;
        u.totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 8;
    }
}