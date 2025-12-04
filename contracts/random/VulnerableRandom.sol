// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
    ⚠️ VULNERABLE RNG CONTRACT ⚠️

    This contract demonstrates insecure randomness in Solidity.
    It uses block.timestamp and block.number to generate a random
    value — but both are PUBLIC and PREDICTABLE.
*/

contract VulnerableRandom {
    uint256 public lastRandom;

    function generateRandom() public returns (uint256) {
        lastRandom = uint256(
            keccak256(abi.encode(block.timestamp, block.number))
        ) % 10;

        return lastRandom;
    }

    function play(uint256 guess) external returns (bool) {
        uint256 rand = generateRandom();

        if (guess == rand) {
            return true;
        } else {
            return false;
        }
    }
}