// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SafeRandom {
    mapping(address => bytes32) public commitments;
    uint256 public lastRandom;

    bytes32 private _lastBlockHash;

    function commit(bytes32 hash) external {
        commitments[msg.sender] = hash;
    }

    function reveal(uint256 secret) external {
        bytes32 expected = keccak256(abi.encodePacked(msg.sender, secret));
        require(commitments[msg.sender] == expected, "bad reveal");

        bytes32 bh = blockhash(block.number - 1);
        _lastBlockHash = bh;

        lastRandom = uint256(
            keccak256(abi.encodePacked(secret, bh))
        ) % 10;

        commitments[msg.sender] = bytes32(0);
    }

    function lastBlockHashUsed() public view returns (bytes32) {
        return _lastBlockHash;
    }
}