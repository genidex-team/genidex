// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../Storage.sol";
import "../Helper.sol";

contract PointFacet {

    modifier onlyRewarder() {
        Storage.UserData storage u = Storage.user();
        if (msg.sender != u.geniRewarder) {
            revert Helper.OnlyRewarderAllowed(msg.sender);
        }
        _;
    }

    function getTotalUnclaimedPoints() external view returns (uint256) {
        Storage.UserData storage u = Storage.user();
        return u.totalUnclaimedPoints;
    }

    function getUserPoints(address userAddress) external view returns (uint256) {
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[userAddress];
        return u.userPoints[userID];
    }

    function deductUserPoints(address userAddress, uint256 pointsToDeduct) external onlyRewarder {
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[userAddress];

        uint256 available = u.userPoints[userID];
        if (available < pointsToDeduct) {
            revert Helper.InsufficientPoints(available, pointsToDeduct);
        }
        u.userPoints[userID] -= pointsToDeduct;
        u.totalUnclaimedPoints -= pointsToDeduct;
    }

    function pointDecimals() public pure returns (uint8) {
        return 8;
    }

    // referral
    function setReferrer(address _referrer) external {
        Storage.UserData storage u = Storage.user();
        if (u.userReferrer[msg.sender] != address(0)) {
            revert Helper.ReferrerAlreadySet(u.userReferrer[msg.sender]);
        }
        if (_referrer == address(0)) {
            revert Helper.InvalidAddress();
        }
        if (_referrer == msg.sender) {
            revert Helper.SelfReferralNotAllowed(msg.sender);
        }
        u.userReferrer[msg.sender] = _referrer;
        u.refereesOf[_referrer].push(msg.sender);
    }

    function migrateReferees(
        bytes32[] calldata proof,
        address[] calldata referees
    ) external {
        Storage.UserData storage u = Storage.user();
        if (u.referralRoot == bytes32(0)) {
            revert Helper.ReferralRootNotSet();
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, referees)))
        );
        if (!MerkleProof.verify(proof, u.referralRoot, leaf)) {
            revert Helper.InvalidProof();
        }
        for (uint256 i = 0; i < referees.length; i++) {
            address referee = referees[i];
            if (u.userReferrer[referee] == address(0) && referee != msg.sender) {
                u.userReferrer[referee] = msg.sender;
                u.refereesOf[msg.sender].push(referee);
            }
        }
    }

}