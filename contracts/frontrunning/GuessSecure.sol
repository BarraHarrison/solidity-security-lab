// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GuessSecure {
    uint256 public rewardPool;
    address public winner;

    mapping(address => bytes32) public commitments;

    constructor() payable {
        rewardPool = msg.value;
    }

    function commit(bytes32 hash) external {
        commitments[msg.sender] = hash;
    }

    function reveal(uint256 guess, uint256 secret, uint256 answer) external {
        bytes32 expected = keccak256(abi.encodePacked(secret, guess));
        require(commitments[msg.sender] == expected, "bad reveal");

        if (guess == answer && winner == address(0)) {
            winner = msg.sender;
            uint256 amount = rewardPool;
            rewardPool = 0;
            (bool ok,) = msg.sender.call{value: amount}("");
            require(ok, "fail");
        }
    }
}