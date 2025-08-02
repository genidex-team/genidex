// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./GeniDexBase.sol";

abstract contract Referral is GeniDexBase {
    function setReferralRoot(bytes32 _referralRoot) external onlyRole(OPERATOR_ROLE) {
        Storage.UserData storage u = Storage.user();
        u.referralRoot = _referralRoot;
    }

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
