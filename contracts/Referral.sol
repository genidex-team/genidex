// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./GeniDexBase.sol";

abstract contract Referral is GeniDexBase {
    function setReferralRoot(bytes32 _referralRoot) external onlyOwner {
        referralRoot = _referralRoot;
    }

    function setReferrer(address _referrer) external {
        require(userReferrer[msg.sender] == address(0), "Referrer already set");
        require(_referrer != address(0), "Invalid referrer address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        userReferrer[msg.sender] = _referrer;
        refereesOf[_referrer].push(msg.sender);
    }

    function getReferees(
        address referrer
    ) external view returns (address[] memory) {
        return refereesOf[referrer];
    }

    function migrateReferees(
        bytes32[] calldata proof,
        address[] calldata referees
    ) external {
        if (referralRoot == bytes32(0)) {
            revert Helper.ReferralRootNotSet("RF33");
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, referees)))
        );
        if (MerkleProof.verify(proof, referralRoot, leaf) != true) {
            revert Helper.InvalidProof("RF39");
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
