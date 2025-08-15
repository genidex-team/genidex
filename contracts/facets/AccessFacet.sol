// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../Storage.sol";
import "../Helper.sol";

contract AccessFacet is AccessManagedUpgradeable, PausableUpgradeable {

    event GeniRewarderUpdated(address indexed previous, address indexed newRewarder);
    event FeeReceiverUpdated(address indexed oldAddress, address indexed newAddress);

    function pause() external restricted {
        _pause();
    }

    function unpause() external restricted {
        _unpause();
    }

    function setGeniRewarder(address _rewarder) external restricted {
        Storage.UserData storage u = Storage.user();
        if (_rewarder == address(0)) {
            revert Helper.InvalidAddress();
        }
        emit GeniRewarderUpdated(u.geniRewarder, _rewarder);
        u.geniRewarder = _rewarder;
    }

    function setReferralRoot(bytes32 _referralRoot) external restricted {
        Storage.UserData storage u = Storage.user();
        u.referralRoot = _referralRoot;
    }

    function updateFeeReceiver(address newAddr) external restricted {
        Storage.UserData storage u = Storage.user();
        if (newAddr == address(0)) revert Helper.InvalidAddress();
        if (u.userIDs[newAddr] != 0) revert Helper.AddressAlreadyLinked();

        address oldAddr = u.userAddresses[FEE_USER_ID];

        u.userAddresses[FEE_USER_ID] = newAddr;
        u.userIDs[newAddr]           = FEE_USER_ID;

        delete u.userIDs[oldAddr];

        emit FeeReceiverUpdated(oldAddr, newAddr);
    }



}
