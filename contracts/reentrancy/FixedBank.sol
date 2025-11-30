// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FixedBank is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    // ✔ Protected with nonReentrant + state update BEFORE external call
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Effects: update state first
        balances[msg.sender] = 0;

        // Interactions: then send ETH
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    function getBankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
