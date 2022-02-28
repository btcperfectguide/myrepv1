// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library StakingEscrowUtils {

    function computeSalt(address vesting, address manager) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(vesting, manager));
    }
}
