// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* ────────────────────────────────────────────────────────────────
 *  GeniDex ‑ Modular Storage Layout (ERC‑7201)
 *  Refactored from the original Storage.sol
 *  ‑ Keeps **constants inline** for zero‑gas reads
 *  ‑ Groups mutable state into four isolated namespaces
 *    1. genidex.core     – global config
 *    2. genidex.market   – order‑book data
 *    3. genidex.token    – token listing config
 *    4. genidex.user  – balances, reward & referral
 *  Upgrades Plugins will validate each namespace independently.
 *  Add NEW fields only at the end of the corresponding struct.
 * ────────────────────────────────────────────────────────────────
 */

// =========  Inline Constants (zero‑gas)  =========
bytes32 constant UPGRADER_ROLE     = keccak256("UPGRADER_ROLE");
bytes32 constant PAUSER_ROLE       = keccak256("PAUSER_ROLE");
bytes32 constant OPERATOR_ROLE     = keccak256("OPERATOR_ROLE");
bytes32 constant FEE_MANAGER_ROLE  = keccak256("FEE_MANAGER_ROLE");

uint256 constant BASE_UNIT      = 10 ** 8;
uint80  constant FEE_USER_ID    = 1;

// =========  Namespaced Storage  =========

library Storage {

    struct Market {
        uint80  price;
        uint80  lastUpdatePrice;
        bool    isRewardable;
        address baseAddress;
        address quoteAddress;
        address creator;
        uint256 id;
        string  symbol;
    }

    struct Order {
        uint80 userID;
        uint80 price;
        uint80 quantity;
    }

    struct OutputOrder {
        uint256 id;
        address trader;
        uint80  userID;
        uint80  price;
        uint80  quantity;
    }

    struct Token {
        uint80 minOrderAmount;
        uint80 minTransferAmount;
        uint80 usdMarketID;
        uint8  decimals;
        bool   isUSD;
        string symbol;
    }

    /* ---------------- 1. CORE ---------------- */
    struct CoreConfig {
        address reader;
    }
    // keccak256(abi.encode(uint256(keccak256("erc7201:genidex.storage.core")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant _CORE_SLOT = 0x9a2e2e549586904174bdcd8d8726c6c9b7a607d07b338753388784501a2ed200;

    /* ---------------- 2. MARKET ---------------- */
    struct MarketData {
        mapping(uint256 => Market)  markets;     // marketId → Market
        mapping(uint256 => Order[]) buyOrders;   // marketId → bids
        mapping(uint256 => Order[]) sellOrders;  // marketId → asks
        mapping(bytes32 => uint256) marketIDs;   // hash(base|quote) → marketId
        uint256 marketCounter; // auto‑increment market id
    }
    // keccak256(abi.encode(uint256(keccak256("erc7201:genidex.storage.market")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant _MARKET_SLOT = 0x0b1393fbf50210466d6f1d484abc24369b62c4f18d8c4568f5a7eaf7736a1800;

    /* ---------------- 3. TOKEN ---------------- */
    struct TokenData {
        mapping(address => Token) tokens;   // tokenAddr → config
        mapping(address => bool)  isListed; // whitelist flag
    }
    // keccak256(abi.encode(uint256(keccak256("erc7201:genidex.storage.token")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant _TOKEN_SLOT = 0xc2a5ee3dbbbbe6cafe347d1ab8d97af8ab3e7dab55fdc3322ef0d694071c0200;

    /* ---------------- 4. USER ---------------- */
    struct UserData {
        // balances[userID][token] → amount
        mapping(uint80 => mapping(address => uint256)) balances;
        // reward points
        mapping(uint80  => uint256) userPoints;
        uint256 totalUnclaimedPoints;
        // user registry
        mapping(address => uint80)  userIDs;
        mapping(uint80  => address) userAddresses;
        // referral tree
        mapping(address => address)   userReferrer;
        mapping(address => address[]) refereesOf;
        bytes32 referralRoot;
        address geniRewarder;
        uint80  userCounter;   // auto‑increment user id
    }
    // keccak256(abi.encode(uint256(keccak256("erc7201:genidex.storage.user")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant _ACCOUNT_SLOT = 0x4d57d3b12dd4d4d89101be88f1ce2740219bed02f011adbd7904947aad814600;

    // =========  Pointer Library =========

    // core()
    function core() internal pure returns (CoreConfig storage s) {
        bytes32 slot = _CORE_SLOT; assembly { s.slot := slot }
    }
    // market()
    function market() internal pure returns (MarketData storage s) {
        bytes32 slot = _MARKET_SLOT; assembly { s.slot := slot }
    }
    // token()
    function token() internal pure returns (TokenData storage s) {
        bytes32 slot = _TOKEN_SLOT; assembly { s.slot := slot }
    }
    // user()
    function user() internal pure returns (UserData storage s) {
        bytes32 slot = _ACCOUNT_SLOT; assembly { s.slot := slot }
    }
}
