// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    // Allow users to deposit ETH
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    // ❌ VULNERABLE: reentrancy in withdraw()
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // ⚠️ External call happens BEFORE state update
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");

        // State update happens AFTER → reentrancy window
        balances[msg.sender] = 0;
    }

    // Helper to see total ETH held by the bank
    function getBankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
