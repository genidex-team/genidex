// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import  "../contracts/GeniDex.sol";
import "../contracts/test/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

library GeniDexHelper {

    function deploy() public returns (GeniDex) {
        GeniDex impl = new GeniDex();
        bytes memory initData =
            abi.encodeWithSignature("initialize(address)", address(this));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        return GeniDex(payable(address(proxy)));
    }
}