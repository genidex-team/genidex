// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";
import "./AppStorage.sol";

abstract contract Points is GeniDexBase {

    modifier onlyRewarder() {
        GeniStorage storage s = AppStorage.getStorage();
        require(msg.sender == s.geniRewarder, "Only RewardDistributor can call");
        _;
    }

    function setGeniRewarder(address _rewarder) external onlyOwner {
        GeniStorage storage s = AppStorage.getStorage();
        s.geniRewarder = _rewarder;
    }

    function updatePoints(
        address quoteAddress,
        address traderAddress,
        uint256 totalTradeValue
    ) internal {
        GeniStorage storage s = AppStorage.getStorage();
        // Token storage baseTotken = tokens[lv.baseAddress];
        Token storage quoteTotken = s.tokens[quoteAddress];
        uint256 points = 0;
        if(quoteTotken.isUSD==true){
            uint8 quoteTotkenDecimals = quoteTotken.decimals;
            if(6 > quoteTotkenDecimals){//point decimals: 6
                points = totalTradeValue * 10**(6-quoteTotkenDecimals);
            }else{
                points = totalTradeValue / 10**(quoteTotkenDecimals-6);
            }
        }else if(quoteTotken.usdMarketID != 0){
            Market storage usdMarket = s.markets[quoteTotken.usdMarketID];
            points = usdMarket.price * totalTradeValue / usdMarket.marketDecimalsPower;
            Token storage usdTotken = s.tokens[usdMarket.quoteAddress];
            uint8 usdTotkenDecimals = usdTotken.decimals;
            if(6 > usdTotkenDecimals){//point decimals: 6
                points = points * 10**(6-usdTotkenDecimals);
            }else{
                points = points / 10**(usdTotkenDecimals-6);
            }
        }
        if(points > 0){
            s.userPoints[traderAddress] += points;
            s.totalUnclaimedPoints += points;

            address ref = s.userReferrer[traderAddress];
            if (ref != address(0)) {
                uint256 refPoints = points * 30 / 100;
                s.userPoints[ref] += refPoints;
                s.totalUnclaimedPoints += refPoints;
            }
        }
    }

    function getTotalUnclaimedPoints() external view returns (uint256) {
        GeniStorage storage s = AppStorage.getStorage();
        return s.totalUnclaimedPoints;
    }

    function getUserPoints(address user) external view returns (uint256) {
        GeniStorage storage s = AppStorage.getStorage();
        return s.userPoints[user];
    }

    function deductUserPoints(address user, uint256 pointsToDeduct) external onlyRewarder {
        GeniStorage storage s = AppStorage.getStorage();
        require(s.userPoints[user] >= pointsToDeduct, "Not enough points");
        s.userPoints[user] -= pointsToDeduct;
        s.totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 6;
    }
}