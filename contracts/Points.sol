// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Storage.sol";

abstract contract Points is Storage{

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
            geniPoints[traderAddress] += points;
            totalPoints += points;
        }
    }
}