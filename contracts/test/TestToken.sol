// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    // Constructor function that initializes the ERC20 token with a custom name, symbol, and initial supply
    // The name, symbol, and initial supply are passed as arguments to the constructor
    uint8 immutable _decimals;

    constructor(
        string memory __name,
        string memory __symbol,
        uint256 initialSupply,
        uint8 __decimals
    ) ERC20(__name, __symbol) {
        // Mint the initial supply of tokens to the deployer's address
        _mint(msg.sender, initialSupply);
        _decimals = __decimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint() public {
        _mint(msg.sender, 100000*10**decimals());
    }

}