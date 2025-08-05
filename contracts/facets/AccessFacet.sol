// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (access/manager/AccessManaged.sol)

pragma solidity ^0.8.20;

import {IAuthority} from "@openzeppelin/contracts/access/manager/IAuthority.sol";
import {AuthorityUtils} from "@openzeppelin/contracts/access/manager/AuthorityUtils.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
// import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {LibAccess} from "../libraries/LibAccess.sol";

/**
 * @dev This contract module makes available a {restricted} modifier. Functions decorated with this modifier will be
 * permissioned according to an "authority": a contract like {AccessManager} that follows the {IAuthority} interface,
 * implementing a policy that allows certain callers to access certain functions.
 *
 * IMPORTANT: The `restricted` modifier should never be used on `internal` functions, judiciously used in `public`
 * functions, and ideally only used in `external` functions. See {restricted}.
 */
contract AccessFacet  {
    error AccessManagedUnauthorized(address caller);
    error AccessManagedInvalidAuthority(address authority);
    event AuthorityUpdated(address authority);

    function authority() public view returns (address) {
        return LibAccess._authority();
    }

    function setAuthority(address newAuthority) public {
        address caller = LibAccess._msgSender();
        if (caller != LibAccess._authority()) {
            revert AccessManagedUnauthorized(caller);
        }
        if (newAuthority.code.length == 0) {
            revert AccessManagedInvalidAuthority(newAuthority);
        }
        _setAuthority(newAuthority);
    }

    function isConsumingScheduledOp() public view returns (bytes4) {
        LibAccess.AccessManagedStorage storage $ = LibAccess._getAccessManagedStorage();
        return $._consumingSchedule ? this.isConsumingScheduledOp.selector : bytes4(0);
    }

    /**
     * @dev Transfers control to a new authority. Internal function with no access restriction. Allows bypassing the
     * permissions set by the current authority.
     */
    function _setAuthority(address newAuthority) internal {
        LibAccess.AccessManagedStorage storage $ = LibAccess._getAccessManagedStorage();
        $._authority = newAuthority;
        emit AuthorityUpdated(newAuthority);
    }
}
