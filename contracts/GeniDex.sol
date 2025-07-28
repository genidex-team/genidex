// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Markets.sol";
import "./BuyOrders.sol";
import "./SellOrders.sol";
import "./Balances.sol";
import "./Tokens.sol";
import "./Referral.sol";
import "./Points.sol";

contract GeniDex is
    Tokens,
    Balances,
    BuyOrders,
    SellOrders,
    Markets,
    Referral,
    Points {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __GeniDexBase_init(initialOwner);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
