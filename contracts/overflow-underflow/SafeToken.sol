// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// ✔ This version is safe.
// Solidity 0.8.0+ automatically checks for overflow/underflow.

contract SafeToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor() {
        totalSupply = 1000;
        balances[msg.sender] = totalSupply;
    }

    // ✔ Safe: arithmetic overflow/underflow reverts automatically
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough balance");
        
        balances[msg.sender] -= amount; // automatic check here
        balances[to] += amount;         // automatic check here
    }

    // ✔ Safe mint: overflow reverts
    function mint(uint256 amount) external {
        totalSupply += amount;          // automatic check here
        balances[msg.sender] += amount; // automatic check here
    }
}