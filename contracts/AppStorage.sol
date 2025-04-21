// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct Market {
    uint256 id;
    string symbol;
    address baseAddress;
    address quoteAddress; //ERC20 token address for the quote asset (e.g., stablecoin)
    uint256 price;
    uint256 lastUpdatePrice;
    uint256 marketDecimalsPower;
    uint8 marketDecimals;
    uint8 priceDecimals;
    uint8 totalDecimals;
    bool isRewardable;
}

struct Order {
    address trader;
    uint256 price;
    uint256 quantity;
}

struct Token {
    bool isUSD;
    uint8 decimals;
    uint256 usdMarketID;
}

struct GeniStorage {
    uint256 marketCounter;
    uint256 totalUnclaimedPoints;
    bytes32 referralRoot;
    address feeReceiver;
    address geniRewarder;

    mapping(uint256 => Market) markets; // marketCounter => Market
    mapping(uint256 => Order[]) buyOrders; // marketID => Order
    mapping(uint256 => Order[]) sellOrders; // marketID => Order
    mapping(address => Token) tokens; // tokenAddress => Token

    // Key: bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
    mapping(bytes32 => uint256) marketIDs; // hash => marketCounter

    mapping(address => mapping(address => uint256)) balances; // userAddress => tokenAddress => balance

    mapping(address => uint256) userPoints;

    mapping(address => address) userReferrer; // referral => referrer
    mapping(address => address[]) refereesOf; // referrer => [referees]

}

library AppStorage {
    bytes32 private constant GENI_POSITION = keccak256("genidex.storage");
    function getStorage() internal pure returns (GeniStorage storage s) {
        bytes32 position = GENI_POSITION;
        assembly {
            s.slot := position
        }
    }
}