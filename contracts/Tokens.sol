// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GeniDexBase.sol";

abstract contract Tokens is GeniDexBase {

    event TokenListed(address indexed token, string symbol);

    function listToken(
        address tokenAddress,
        uint80 minTransferAmount,
        uint80 minOrderAmount,
        uint80 usdMarketID,
        bool isUSD,
        bool autoDetect,
        string calldata manualSymbol,
        uint8 manualDecimals
    ) external onlyRole(OPERATOR_ROLE) {
        // if (tokenAddress == address(0)) revert Helper.InvalidTokenAddress();
        // if (isTokenListed[tokenAddress]) revert Helper.TokenAlreadyListed(tokenAddress);

        string memory symbol;
        uint8 decimals;

        if(tokenAddress == address(0)){
            symbol = 'ETH';
            decimals = 18;
        }else if (autoDetect) {
            try IERC20Metadata(tokenAddress).symbol() returns (string memory sym) {
                symbol = sym;
            } catch {
                revert Helper.SymbolFetchFailed();
            }

            try IERC20Metadata(tokenAddress).decimals() returns (uint8 dec) {
                decimals = dec;
            } catch {
                revert Helper.DecimalsFetchFailed();
            }
        } else {
            if (bytes(manualSymbol).length == 0) revert Helper.ManualSymbolRequired();
            if (manualDecimals == 0) revert Helper.ManualDecimalsRequired();
            symbol = manualSymbol;
            decimals = manualDecimals;
        }

        tokens[tokenAddress] = Token({
            symbol: symbol,
            usdMarketID: usdMarketID,
            minOrderAmount: minOrderAmount,
            minTransferAmount: minTransferAmount,
            decimals: decimals,
            isUSD: isUSD
        });

        isTokenListed[tokenAddress] = true;

        emit TokenListed(tokenAddress, symbol);
    }

    function updateTokenIsUSD(address tokenAddress, bool isUSD) external onlyRole(OPERATOR_ROLE){
        tokens[tokenAddress].isUSD = isUSD;
    }

    function updateUSDMarketID(address tokenAddress, uint80 marketID) external onlyRole(OPERATOR_ROLE){
        tokens[tokenAddress].usdMarketID = marketID;
    }

    function updateMinOrderAmount(address tokenAddress, uint80 minOrderAmount) external onlyRole(OPERATOR_ROLE){
        tokens[tokenAddress].minOrderAmount = minOrderAmount;
    }

    function updateMinTransferAmount(address tokenAddress, uint80 minTransferAmount) external onlyRole(OPERATOR_ROLE){
        tokens[tokenAddress].minTransferAmount = minTransferAmount;
    }

    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint80 usdMarketID;
        uint80 minOrderAmount;
        uint80 minTransferAmount;
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
                minTransferAmount: info.minTransferAmount,
                decimals: info.decimals,
                isUSD: info.isUSD
            });
        }
        return result;
    }

}