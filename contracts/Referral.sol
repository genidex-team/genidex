// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./GeniDexBase.sol";
import "./Helper.sol";
import "./AppStorage.sol";

abstract contract Referral is GeniDexBase {
    function setReferralRoot(bytes32 _referralRoot) external onlyOwner {
        GeniStorage storage s = AppStorage.getStorage();
        s.referralRoot = _referralRoot;
    }

    function setReferrer(address _referrer) external {
        GeniStorage storage s = AppStorage.getStorage();
        require(s.userReferrer[msg.sender] == address(0), "Referrer already set");
        require(_referrer != address(0), "Invalid referrer address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        s.userReferrer[msg.sender] = _referrer;
        s.refereesOf[_referrer].push(msg.sender);
    }

    function getReferees(
        address referrer
    ) external view returns (address[] memory) {
        GeniStorage storage s = AppStorage.getStorage();
        return s.refereesOf[referrer];
    }

    function migrateReferees(
        bytes32[] calldata proof,
        address[] calldata referees
    ) external {
        GeniStorage storage s = AppStorage.getStorage();
        if (s.referralRoot == bytes32(0)) {
            revert Helper.ReferralRootNotSet("RF33");
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, referees)))
        );
        if (MerkleProof.verify(proof, s.referralRoot, leaf) != true) {
            revert Helper.InvalidProof("RF39");
        }
        for (uint256 i = 0; i < referees.length; i++) {
            address referee = referees[i];
            if (s.userReferrer[referee] == address(0) && referee != msg.sender) {
                s.userReferrer[referee] = msg.sender;
                s.refereesOf[msg.sender].push(referee);
            }
        }
    }
}
