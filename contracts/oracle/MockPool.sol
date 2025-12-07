// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract MockPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    function getBalances() external view returns (uint256, uint256) {
        return (
            tokenA.balanceOf(address(this)),
            tokenB.balanceOf(address(this))
        );
    }
}