// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Helper.sol";

abstract contract Storage {

    enum OrderType {
        Buy,
        Sell
    }

    struct Market {
        uint80 price;
        uint80 lastUpdatePrice;
        bool isRewardable;
        address baseAddress;
        address quoteAddress; //ERC20 token address for the quote asset (e.g., stablecoin)
        address creator;
        uint256 id;
        string symbol;
    }

    struct Order {
        uint80 userID;
        uint80 price;
        uint80 quantity;
    }

    struct OutputOrder {
        uint256 id;
        address trader;
        uint80 userID;
        uint80 price;
        uint80 quantity;
    }

    struct Token {
        uint80 minOrderAmount;
        uint80 minTransferAmount;
        uint80 usdMarketID;
        uint8 decimals;
        bool isUSD;
        string symbol;
    }

    uint256 public constant BASE_UNIT = 10 ** 8;
    uint80 internal constant FEE_USER_ID = 1;

    mapping(uint256 => Market) public markets; // marketCounter => Market
    mapping(uint256 => Order[]) public buyOrders; // marketID => Order[]
    mapping(uint256 => Order[]) public sellOrders; // marketID => Order[]
    mapping(address => Token) public tokens; // tokenAddress => Token
    mapping(address => bool) public isTokenListed;
    // Key: bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
    mapping(bytes32 => uint256) public marketIDs; // hash => marketCounter
    mapping(uint80 userID => mapping(address token => uint256 balance)) public balances; // balances[userID][token] => balance
    mapping(uint80 userID => uint256) public userPoints;
    mapping(address => uint80) public userIDs; // userIDs[userAddress] = userID
    mapping(uint80 => address) public userAddresses; // userAddresses[userID] = userAddress
    mapping(address => address) public userReferrer; // referee => referrer
    mapping(address => address[]) public refereesOf; // referrer => [referees]

    uint256 public marketCounter;
    uint80 public userCounter;
    uint256 public totalUnclaimedPoints;
    bytes32 public referralRoot;
    address public geniRewarder;

}
