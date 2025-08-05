// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

contract AdminFacet is AccessManagedUpgradeable {

    function init(address accessManager) public{
        __AccessManaged_init(accessManager);
    }
}
