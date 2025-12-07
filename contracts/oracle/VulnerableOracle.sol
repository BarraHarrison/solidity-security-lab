// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract VulnerableOracle {
    address public immutable tokenA;
    address public immutable tokenB;
    address public immutable pool;

    constructor(address _tokenA, address _tokenB, address _pool) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        pool  = _pool;
    }

    /// @notice Returns the price of 1 tokenA in terms of tokenB, scaled by 1e18
    function getPrice() external view returns (uint256) {
        uint256 reserveA = IERC20(tokenA).balanceOf(pool);
        uint256 reserveB = IERC20(tokenB).balanceOf(pool);

        require(reserveA > 0, "no liquidity");

        // Price with 18 decimals: tokenB per 1 tokenA
        return (reserveB * 1e18) / reserveA;
    }
}