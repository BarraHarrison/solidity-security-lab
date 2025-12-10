// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC20 interface compatible with your MockERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract VulnerableDEX {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0), "zero tokenA");
        require(_tokenB != address(0), "zero tokenB");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _getReserves()
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }


    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "zero amounts");
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "transferFrom A failed"
        );
        require(
            tokenB.transferFrom(msg.sender, address(this), amountB),
            "transferFrom B failed"
        );
        // No LP tokens minted — this is intentionally oversimplified
    }

    function swapAForB(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "zero amountIn");

        (uint256 reserveA, uint256 reserveB) = _getReserves();
        require(reserveA > 0 && reserveB > 0, "empty pool");

        uint256 k = reserveA * reserveB;

        uint256 newReserveA = reserveA + amountIn;

        uint256 newReserveB = k / newReserveA;

        require(newReserveB < reserveB, "no output");
        amountOut = reserveB - newReserveB;

        require(
            tokenA.transferFrom(msg.sender, address(this), amountIn),
            "transferFrom A failed"
        );

        require(
            tokenB.transfer(msg.sender, amountOut),
            "transfer B failed"
        );
    }

    function swapBForA(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "zero amountIn");

        (uint256 reserveA, uint256 reserveB) = _getReserves();
        require(reserveA > 0 && reserveB > 0, "empty pool");

        uint256 k = reserveA * reserveB;
        uint256 newReserveB = reserveB + amountIn;
        uint256 newReserveA = k / newReserveB;

        require(newReserveA < reserveA, "no output");
        amountOut = reserveA - newReserveA;

        require(
            tokenB.transferFrom(msg.sender, address(this), amountIn),
            "transferFrom B failed"
        );
        require(
            tokenA.transfer(msg.sender, amountOut),
            "transfer A failed"
        );
    }

    function getPriceAinB() external view returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = _getReserves();
        require(reserveA > 0 && reserveB > 0, "empty pool");
        return (reserveB * 1e18) / reserveA;
    }

    function getPriceBinA() external view returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = _getReserves();
        require(reserveA > 0 && reserveB > 0, "empty pool");
        return (reserveA * 1e18) / reserveB;
    }
}
