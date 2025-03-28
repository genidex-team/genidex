// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Storage.sol";

abstract contract Tokens is Storage, OwnableUpgradeable{

    function updateTokenIsUSD(address tokenAddress, bool isUSD) public onlyOwner(){
        ERC20 token = ERC20(tokenAddress);
        tokens[tokenAddress].isUSD = isUSD;
        tokens[tokenAddress].decimals = token.decimals();
    }

    function updateUSDMarketID(address tokenAddress, uint256 marketID) public onlyOwner{
        tokens[tokenAddress].usdMarketID = marketID;
    }

    struct TokenInfo {
        address tokenAddress;
        bool isUSD;
        uint8 decimals;
        uint256 usdMarketID;
    }

    function getTokensInfo(address[] calldata tokenAddresses) external view returns (TokenInfo[] memory) {
        uint256 length = tokenAddresses.length;
        TokenInfo[] memory result = new TokenInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            Token memory info = tokens[tokenAddresses[i]];
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