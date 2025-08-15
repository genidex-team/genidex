// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../Storage.sol";

library LibOrder {
    function _updatePoints(
        address quoteAddress,
        uint80 userID,
        uint256 totalTradeValue
    ) internal {
        Storage.TokenData storage t = Storage.token();
        Storage.MarketData storage m = Storage.market();
        Storage.UserData storage u = Storage.user();
        Storage.Token storage quoteToken = t.tokens[quoteAddress];
        uint256 points = 0;
        if(quoteToken.isUSD){
            points = totalTradeValue;
        }else if(quoteToken.usdMarketID != 0){
            Storage.Market storage usdMarket = m.markets[quoteToken.usdMarketID];
            points = usdMarket.price * totalTradeValue / BASE_UNIT;
        }
        if(points > 0){
            u.userPoints[userID] += points;
            u.totalUnclaimedPoints += points;

            /*address ref = userReferrer[traderAddress];
            if (ref != address(0)) {
                uint256 refPoints = points * 30 / 100;
                userPoints[ref] += refPoints;
                totalUnclaimedPoints += refPoints;
            }*/
        }
    }
}