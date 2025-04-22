// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

import "./Helper.sol";

abstract contract Storage is GeniDexBase {
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

    mapping(uint256 => Market) public markets; // marketCounter => Market
    mapping(uint256 => Order[]) public buyOrders; // marketID => Order[]
    mapping(uint256 => Order[]) public sellOrders; // marketID => Order[]
    mapping(address => Token) public tokens;
    // Key: bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
    mapping(bytes32 => uint256) public marketIDs; // hash => marketCounter
    mapping(address => mapping(address => uint256)) balances;
    mapping(address => uint256) public userPoints;
    mapping(address => address) public userReferrer; // referral => referrer
    mapping(address => address[]) public refereesOf; // referrer => [referees]

    uint256 public marketCounter;
    uint256 public totalUnclaimedPoints;
    bytes32 public referralRoot;

    address public constant feeReceiver = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public geniRewarder;

    function __Storage_init() internal onlyInitializing {
        marketCounter = 0;
        totalUnclaimedPoints = 0;
    }

    function fee(uint256 amount) internal pure returns (uint256 result) {
        // 0.1% = 0.001 = 1/1000
        result = amount / 1000;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}
