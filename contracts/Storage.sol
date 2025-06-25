// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Helper.sol";

abstract contract Storage {

    enum OrderType {
        Buy,
        Sell
    }

    struct Market {
        string symbol;
        uint256 id;
        uint256 price;
        uint256 lastUpdatePrice;
        address baseAddress;
        address quoteAddress; //ERC20 token address for the quote asset (e.g., stablecoin)
        address creator;
        bool isRewardable;
    }

    struct Order {
        uint80 userID;
        uint80 price;
        uint80 quantity;
    }

    struct OutputOrder {
        uint256 id;
        uint80 userID;
        uint80 price;
        uint80 quantity;
    }

    struct Token {
        string symbol;
        uint256 usdMarketID;
        uint256 minOrderAmount;
        uint256 minTransferAmount;
        uint8 decimals;
        bool isUSD;
    }

    uint256 public constant WAD = 10 ** 8;

    mapping(uint256 => Market) public markets; // marketCounter => Market
    mapping(uint256 => Order[]) public buyOrders; // marketID => Order[]
    mapping(uint256 => Order[]) public sellOrders; // marketID => Order[]
    mapping(address => Token) public tokens; // tokenAddress => Token
    // Key: bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
    mapping(bytes32 => uint256) public marketIDs; // hash => marketCounter
    mapping(uint80 userID => mapping(address token => uint256 balance)) public balances; // balances[userID][token] => balance
    mapping(uint80 userID => uint256) public userPoints;
    mapping(address => uint80) public userIDs;
    mapping(address => address) public userReferrer; // referee => referrer
    mapping(address => address[]) public refereesOf; // referrer => [referees]

    uint256 public marketCounter;
    uint80 public userCounter;
    uint256 public totalUnclaimedPoints;
    bytes32 public referralRoot;

    address public constant feeReceiver = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public geniRewarder;


}
