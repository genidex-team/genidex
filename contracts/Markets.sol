// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract Markets is GeniDexBase {

    function addMarket(
        address baseAddress, address quoteAddress
    ) external onlyRole(OPERATOR_ROLE) {
        string memory baseSymbol;
        string memory quoteSymbol;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        (baseSymbol, baseDecimals) = _getTokenMeta(baseAddress);
        (quoteSymbol, quoteDecimals) = _getTokenMeta(quoteAddress);

        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        if (marketIDs[hash] != 0) {
            revert Helper.MarketAlreadyExists(baseAddress, quoteAddress);
        }
        marketCounter++;

        markets[marketCounter] = Market({
            symbol: string(abi.encodePacked(baseSymbol, '_', quoteSymbol)),
            id: marketCounter,
            price: 0,
            lastUpdatePrice: 0,
            baseAddress: baseAddress,
            quoteAddress: quoteAddress,
            creator: msg.sender,
            isRewardable: false
        });
        marketIDs[hash] = marketCounter;

    }

    function getMarketID(address baseAddress, address quoteAddress) external view returns(uint256){
        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        return marketIDs[hash];
    }

    function getMarket(uint256 id) external view returns(Market memory) {
        return markets[id];
    }

    function generateMarketHash(address baseAddress, address quoteAddress) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
        return hash;
    }

    function getAllMarkets() external view returns(Market[] memory) {
        Market[] memory outputMarkets = new Market[](marketCounter);
        for(uint256 i=1; i<=marketCounter; i++){
            outputMarkets[i-1] = markets[i];
        }
        return outputMarkets;
    }

    function updateMarketIsRewardable(uint256 marketId, bool isRewardable) public onlyRole(OPERATOR_ROLE) {
        markets[marketId].isRewardable = isRewardable;
    }

}