// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeToken is ERC20 {
    // uint256 public constant FEE_BPS = 100; // 1 % (1/10000)
    uint8 private immutable _decimals;
    constructor(string memory n, string memory s, uint8 d, uint256 init) ERC20(n,s) {
        _decimals = d;
        _mint(msg.sender, init * 1e18);
    }
    function decimals() public view override returns (uint8){ return _decimals; }

    function mint(address account, uint256 value) public{
        super._mint(account, value);
    }

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override
    {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
            return;
        }

        uint256 fee = value / 100;     // 1 %
        uint256 sendAmount = value - fee;

        super._update(from, address(0), fee);         // burn
        super._update(from, to,           sendAmount);
    }
}