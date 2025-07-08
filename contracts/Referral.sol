// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./GeniDexBase.sol";

abstract contract Referral is GeniDexBase {
    function setReferralRoot(bytes32 _referralRoot) external onlyOwner {
        referralRoot = _referralRoot;
    }

    function setReferrer(address _referrer) external {
        if (userReferrer[msg.sender] != address(0)) {
            revert Helper.ReferrerAlreadySet(userReferrer[msg.sender]);
        }
        if (_referrer == address(0)) {
            revert Helper.InvalidAddress();
        }
        if (_referrer == msg.sender) {
            revert Helper.SelfReferralNotAllowed(msg.sender);
        }
        userReferrer[msg.sender] = _referrer;
        refereesOf[_referrer].push(msg.sender);
    }

    function getReferees(
        address referrer
    ) external view returns (address[] memory) {
        return refereesOf[referrer];
    }

    function getReferrer(
        address referee
    ) external view returns (address) {
        return userReferrer[referee];
    }

    function migrateReferees(
        bytes32[] calldata proof,
        address[] calldata referees
    ) external {
        if (referralRoot == bytes32(0)) {
            revert Helper.ReferralRootNotSet();
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, referees)))
        );
        if (!MerkleProof.verify(proof, referralRoot, leaf)) {
            revert Helper.InvalidProof();
        }
        for (uint256 i = 0; i < referees.length; i++) {
            address referee = referees[i];
            if (userReferrer[referee] == address(0) && referee != msg.sender) {
                userReferrer[referee] = msg.sender;
                refereesOf[msg.sender].push(referee);
            }
        }
    }
}
