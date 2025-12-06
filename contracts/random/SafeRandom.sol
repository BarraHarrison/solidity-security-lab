// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SafeRandom {
    mapping(address => bytes32) public commitments;
    uint256 public lastRandom;

    /// @notice User commits to a secret by sending its hash
    /// @param hash keccak256(abi.encodePacked(msg.sender, secret))
    function commit(bytes32 hash) external {
        commitments[msg.sender] = hash;
    }

    /// @notice User reveals their secret; contract verifies and generates randomness
    /// @param secret The original secret used when computing the commitment hash
    /// @return random The generated random number between 0 and 9
    function reveal(uint256 secret) external returns (uint256 random) {
        // Rebuild the commitment we expect
        bytes32 expected = keccak256(abi.encodePacked(msg.sender, secret));
        require(commitments[msg.sender] == expected, "invalid reveal");

        // Use the previous blockhash as additional entropy
        bytes32 bh = blockhash(block.number - 1);
        require(bh != bytes32(0), "no blockhash");

        random = uint256(keccak256(abi.encodePacked(secret, bh))) % 10;
        lastRandom = random;

        // Clear the commitment so it can't be reused
        delete commitments[msg.sender];

        return random;
    }
}