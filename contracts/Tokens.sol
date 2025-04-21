// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GeniDexBase.sol";
import "./AppStorage.sol";

abstract contract Tokens is GeniDexBase {

    function updateTokenIsUSD(address tokenAddress, bool isUSD) public onlyOwner(){
        GeniStorage storage s = AppStorage.getStorage();
        ERC20 token = ERC20(tokenAddress);
        s.tokens[tokenAddress].isUSD = isUSD;
        s.tokens[tokenAddress].decimals = token.decimals();
    }

    function updateUSDMarketID(address tokenAddress, uint256 marketID) public onlyOwner{
        GeniStorage storage s = AppStorage.getStorage();
        s.tokens[tokenAddress].usdMarketID = marketID;
    }

    struct TokenInfo {
        address tokenAddress;
        bool isUSD;
        uint8 decimals;
        uint256 usdMarketID;
    }

    function getTokenInfo(address tokenAddress) external view returns (TokenInfo memory) {
        GeniStorage storage s = AppStorage.getStorage();
        Token memory info = s.tokens[tokenAddress];
        return TokenInfo({
            tokenAddress: tokenAddress,
            isUSD: info.isUSD,
            decimals: info.decimals,
            usdMarketID: info.usdMarketID
        });
    }

    function getTokensInfo(address[] calldata tokenAddresses) external view returns (TokenInfo[] memory) {
        GeniStorage storage s = AppStorage.getStorage();
        uint256 length = tokenAddresses.length;
        TokenInfo[] memory result = new TokenInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            Token memory info = s.tokens[tokenAddresses[i]];
            result[i] = TokenInfo({
                tokenAddress: tokenAddresses[i],
                isUSD: info.isUSD,
                decimals: info.decimals,
                usdMarketID: info.usdMarketID
            });
        }
        return result;
    }

}