// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Storage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Points is Storage, OwnableUpgradeable {

    modifier onlyRewarder() {
        require(msg.sender == geniRewarder, "Only RewardDistributor can call");
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyOwner {
        geniRewarder = _rewarder;
    }

    function updatePoints(address quoteAddress, address traderAddress,
        uint256 totalTradeValue) internal {
        // Token storage baseTotken = tokens[lv.baseAddress];
        Token storage quoteTotken = tokens[quoteAddress];
        uint256 points = 0;
        if(quoteTotken.isUSD==true){
            uint8 quoteTotkenDecimals = quoteTotken.decimals;
            if(6 > quoteTotkenDecimals){//point decimals: 6
                points = totalTradeValue * 10**(6-quoteTotkenDecimals);
            }else{
                points = totalTradeValue / 10**(quoteTotkenDecimals-6);
            }
        }else if(quoteTotken.usdMarketID != 0){
            Market storage usdMarket = markets[quoteTotken.usdMarketID];
            points = usdMarket.price * totalTradeValue / usdMarket.marketDecimalsPower;
            Token storage usdTotken = tokens[usdMarket.quoteAddress];
            uint8 usdTotkenDecimals = usdTotken.decimals;
            if(6 > usdTotkenDecimals){//point decimals: 6
                points = points * 10**(6-usdTotkenDecimals);
            }else{
                points = points / 10**(usdTotkenDecimals-6);
            }
        }
        if(points > 0){
            userPoints[traderAddress] += points;
            totalUnclaimedPoints += points;

            address ref = userReferrer[traderAddress];
            if (ref != address(0)) {
                uint256 refPoints = points * 30 / 100;
                userPoints[ref] += refPoints;
                totalUnclaimedPoints += refPoints;
            }
        }
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