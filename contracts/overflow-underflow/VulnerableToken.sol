// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

// ❗ This contract is intentionally vulnerable.
// Solidity <0.8.0 does NOT check for arithmetic overflow or underflow.

contract VulnerableToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor() {
        totalSupply = 1000;
        balances[msg.sender] = totalSupply;
    }

    // ❌ Vulnerable: No overflow/underflow checks
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough balance");

        balances[msg.sender] -= amount; // may underflow
        balances[to] += amount;         // may overflow
    }

    // ❌ Vulnerable mint: can overflow totalSupply
    function mint(uint256 amount) external {
        totalSupply += amount;          // may overflow
        balances[msg.sender] += amount; // may overflow
    }
}
