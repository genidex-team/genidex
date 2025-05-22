// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract _IncludeProxy is ERC1967Proxy {
    constructor() ERC1967Proxy(address(0), "") {}
}