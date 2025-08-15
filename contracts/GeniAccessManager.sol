// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GeniAccessManager is AccessManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // roleId => set of member addresses
    mapping(uint64 => EnumerableSet.AddressSet) private _roleMembers;
    EnumerableSet.UintSet private _allRoles;

    constructor() AccessManager(msg.sender) {
        _roleMembers[ADMIN_ROLE].add(msg.sender);
        _allRoles.add(ADMIN_ROLE);
    }

    /* ---------- write ---------- */

    /// @inheritdoc AccessManager
    function grantRole(
        uint64 roleId,
        address account,
        uint32 executionDelay
    ) public virtual override {
        super.grantRole(roleId, account, executionDelay);
        _roleMembers[roleId].add(account);
        _allRoles.add(roleId);
    }

    /// @inheritdoc AccessManager
    function revokeRole(uint64 roleId, address account)
        public
        virtual
        override
    {
        super.revokeRole(roleId, account);
        _roleMembers[roleId].remove(account);
    }

    /// @inheritdoc AccessManager
    function renounceRole(uint64 roleId, address callerConfirmation)
        public
        virtual
        override
    {
        super.renounceRole(roleId, callerConfirmation);
        _roleMembers[roleId].remove(msg.sender);
    }

    /* ---------- read ---------- */

    // --- Role catalogue ---
    function getRoleCount() external view returns (uint256) {
        return _allRoles.length();
    }

    function getRoleByIndex(uint256 index) external view returns (uint64) {
        return uint64(_allRoles.at(index));
    }

    /// @dev Returns address at `index` for `roleId`.
    function getRoleMember(uint64 roleId, uint256 index)
        external
        view
        returns (address)
    {
        return _roleMembers[roleId].at(index);
    }

    /// @dev Returns number of members for `roleId`.
    function getRoleMemberCount(uint64 roleId)
        external
        view
        returns (uint256)
    {
        return _roleMembers[roleId].length();
    }

    /// @notice Returns **every** account that currently holds `roleId`.
    /// @dev Order is arbitrary (inner EnumerableSet iteration order).
    function getRoleMembers(uint64 roleId)
        external
        view
        returns (address[] memory)
    {
        uint256 len = _roleMembers[roleId].length();
        address[] memory members = new address[](len);
        for (uint256 i; i < len; ++i) {
            members[i] = _roleMembers[roleId].at(i);
        }
        return members;
    }

    /// @notice Returns the list of all roleIds that have ever been tracked.
    /// @dev Roles are stored in a single-bucket EnumerableSet ⇒ order arbitrary.
    ///      RoleIds remain in the set even if their member count drops to zero.
    function getAllRoles() external view returns (uint64[] memory) {
        uint256 len = _allRoles.length();
        uint64[] memory roles = new uint64[](len);
        for (uint256 i; i < len; ++i) {
            roles[i] = uint64(_allRoles.at(i));
        }
        return roles;
    }

    struct SelectorRole {
        bytes4 selector;
        uint64 roleId;
    }

    function getTargetFunctionRoles(address target, bytes4[] calldata selectors) external view returns (SelectorRole[] memory roleIds) {
        uint256 len = selectors.length;
        roleIds = new SelectorRole[](len);

        for (uint256 i; i < len; ) {
            roleIds[i] = SelectorRole({
                selector: selectors[i],
                roleId: getTargetFunctionRole(target, selectors[i])
            });
            unchecked { ++i; }
        }
    }
}
