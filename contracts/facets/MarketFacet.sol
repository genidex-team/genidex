// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Storage.sol";
import "../Helper.sol";
import "../libraries/LibAccessManaged.sol";

contract MarketFacet is LibAccessManaged {

    function addMarket(
        address baseAddress, address quoteAddress
    ) external restricted {
        Storage.MarketData storage m = Storage.market();

        string memory baseSymbol;
        string memory quoteSymbol;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        (baseSymbol, baseDecimals) = _getTokenMeta(baseAddress);
        (quoteSymbol, quoteDecimals) = _getTokenMeta(quoteAddress);

        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        if (m.marketIDs[hash] != 0) {
            revert Helper.MarketAlreadyExists(baseAddress, quoteAddress);
        }
        m.marketCounter++;

        m.markets[m.marketCounter] = Storage.Market({
            symbol: string(abi.encodePacked(baseSymbol, '_', quoteSymbol)),
            id: m.marketCounter,
            price: 0,
            lastUpdatePrice: 0,
            baseAddress: baseAddress,
            quoteAddress: quoteAddress,
            creator: msg.sender,
            isRewardable: false
        });
        m.marketIDs[hash] = m.marketCounter;

    }

    function updateMarketIsRewardable(uint256 marketId, bool isRewardable) external restricted{
        Storage.MarketData storage m = Storage.market();
        m.markets[marketId].isRewardable = isRewardable;
    }

    function generateMarketHash(address baseAddress, address quoteAddress) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
        return hash;
    }

    function _getTokenMeta(address tokenAddress) internal view returns (string memory symbol, uint8 decimals) {
        Storage.TokenData storage t = Storage.token();
        Storage.Token storage info = t.tokens[tokenAddress];
        if(!t.isListed[tokenAddress]){
            revert Helper.TokenNotListed(tokenAddress);
        }
        return (info.symbol, info.decimals);
    }

}