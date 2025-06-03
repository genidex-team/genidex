// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GeniDexBase.sol";

abstract contract Tokens is GeniDexBase {

    function updateTokenIsUSD(address tokenAddress, bool isUSD) external onlyOwner(){
        ERC20 token = ERC20(tokenAddress);
        tokens[tokenAddress].isUSD = isUSD;
        tokens[tokenAddress].decimals = token.decimals();
    }

    function updateUSDMarketID(address tokenAddress, uint256 marketID) external onlyOwner{
        tokens[tokenAddress].usdMarketID = marketID;
    }

    function updateMinOrderAmount(address tokenAddress, uint256 minOrderAmount) external onlyOwner{
        tokens[tokenAddress].minOrderAmount = minOrderAmount;
    }

    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 usdMarketID;
        uint256 minOrderAmount;
        uint8 decimals;
        bool isUSD;
    }

    function getTokensInfo(address[] calldata tokenAddresses) external view returns (TokenInfo[] memory) {
        uint256 length = tokenAddresses.length;
        TokenInfo[] memory result = new TokenInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            Token memory info = tokens[tokenAddresses[i]];
            result[i] = TokenInfo({
                tokenAddress: tokenAddresses[i],
                symbol: info.symbol,
                usdMarketID: info.usdMarketID,
                minOrderAmount: info.minOrderAmount,
                decimals: info.decimals,
                isUSD: info.isUSD
            });
        }
        return result;
    }

}