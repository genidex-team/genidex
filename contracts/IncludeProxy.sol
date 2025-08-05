// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/manager/AccessManager.sol";
contract _IncludeProxy is ERC1967Proxy {
    constructor() ERC1967Proxy(address(0), "") {}
}
contract _AccessManager is AccessManager {
    constructor() AccessManager(address(0)) {}
}