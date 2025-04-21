// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

import "./Markets.sol";
import "./BuyOrders.sol";
import "./SellOrders.sol";
import "./Balances.sol";
import "./Tokens.sol";
import "./Referral.sol";

contract GeniDex is
    GeniDexBase,
    Referral,
    Tokens,
    Balances,
    BuyOrders,
    SellOrders,
    Markets {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __GeniDexBase_init(initialOwner);
    }
}
