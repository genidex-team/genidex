// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    // Constructor function that initializes the ERC20 token with a custom name, symbol, and initial supply
    // The name, symbol, and initial supply are passed as arguments to the constructor
    uint8 _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals_
    ) ERC20(name, symbol) {
        // Mint the initial supply of tokens to the deployer's address
        _mint(msg.sender, initialSupply);
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint() public {
        _mint(msg.sender, 100000*10**decimals());
    }

}