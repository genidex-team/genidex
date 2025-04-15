// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Storage.sol";

abstract contract Markets is Storage{

    function addMarket(address baseAddress, address quoteAddress) external {

        uint8 baseDecimals;
        uint8 quoteDecimals;
        string memory baseSymbol;
        string memory quoteSymbol;
        if(baseAddress == address(0)){ // ETH
            baseDecimals = 18;
            baseSymbol = 'ETH';
        }else{
            ERC20 baseToken = ERC20(baseAddress);
            baseDecimals = baseToken.decimals();
            baseSymbol = baseToken.symbol();
        }
        if(quoteAddress == address(0)){ // ETH
            quoteDecimals = 18;
            quoteSymbol = 'ETH';
        }else{
            ERC20 quoteToken = ERC20(quoteAddress);
            quoteDecimals = quoteToken.decimals();
            quoteSymbol = quoteToken.symbol();
        }

        uint256 marketDecimalsPower;
        uint8 marketDecimals;
        uint8 priceDecimals;
        uint8 totalDecimals;
        if(quoteDecimals > 18 + baseDecimals){ //quoteDecimals - baseDecimals > 18
            priceDecimals = quoteDecimals - baseDecimals;
            marketDecimals = 0;
        }else{
            priceDecimals = 18;
            marketDecimals = priceDecimals + baseDecimals - quoteDecimals;
            //marketDecimals = 18 - (quoteDecimals - baseDecimals)
        }
        marketDecimalsPower = 10**marketDecimals;
        totalDecimals = quoteDecimals;
        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        require(marketIDs[hash]==0, 'Market already exists.');
        marketCounter++;
        markets[marketCounter] = Market({
            id: marketCounter,
            symbol: string(abi.encodePacked(baseSymbol, '_', quoteSymbol)),
            baseAddress: baseAddress,
            quoteAddress: quoteAddress,
            price: 0,
            lastUpdatePrice: 0,
            marketDecimalsPower: marketDecimalsPower,
            marketDecimals: marketDecimals,
            priceDecimals: priceDecimals,
            totalDecimals: totalDecimals,
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

    function updateMarketIsRewardable(uint256 marketId, bool isRewardable) public onlyOwner() {
        markets[marketId].isRewardable = isRewardable;
    }

}