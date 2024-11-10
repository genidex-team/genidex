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
    //updateTokenIsUSD
    function updateUSDMarketID(address tokenAddress, uint256 marketID) public onlyOwner{
        tokens[tokenAddress].usdMarketID = marketID;
    }
}