// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../Storage.sol";
import "../Helper.sol";
import "../libraries/LibAccessManaged.sol";

contract TokenFacet is LibAccessManaged {

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
    ) external restricted {
        Storage.TokenData storage t = Storage.token();
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

        t.tokens[tokenAddress] = Storage.Token({
            symbol: symbol,
            usdMarketID: usdMarketID,
            minOrderAmount: minOrderAmount,
            minTransferAmount: minTransferAmount,
            decimals: decimals,
            isUSD: isUSD
        });

        t.isListed[tokenAddress] = true;

        emit TokenListed(tokenAddress, symbol);
    }

    function updateTokenIsUSD(address tokenAddress, bool isUSD) external restricted{
        Storage.TokenData storage t = Storage.token();
        t.tokens[tokenAddress].isUSD = isUSD;
    }

    function updateUSDMarketID(address tokenAddress, uint80 marketID) external restricted{
        Storage.TokenData storage t = Storage.token();
        t.tokens[tokenAddress].usdMarketID = marketID;
    }

    function updateMinOrderAmount(address tokenAddress, uint80 minOrderAmount) external restricted{
        Storage.TokenData storage t = Storage.token();
        t.tokens[tokenAddress].minOrderAmount = minOrderAmount;
    }

    function updateMinTransferAmount(address tokenAddress, uint80 minTransferAmount) external restricted{
        Storage.TokenData storage t = Storage.token();
        t.tokens[tokenAddress].minTransferAmount = minTransferAmount;
    }

}