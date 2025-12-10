// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SafeDEX {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public constant MAX_TRADE_BPS = 1000; // 10%

    uint256 public constant MAX_PRICE_IMPACT_BPS = 5000; // 50%

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
    }

    function _checkMaxTrade(uint256 amountIn, uint256 reserveIn) internal pure {
        uint256 maxTrade = (reserveIn * MAX_TRADE_BPS) / 10_000;
        require(amountIn <= maxTrade, "trade too large");
    }


    function _checkPriceImpact(
        uint256 oldPrice, // scaled by 1e18
        uint256 newPrice  // scaled by 1e18
    ) internal pure {
        if (oldPrice == 0) return; // nothing to compare

        uint256 diff = oldPrice > newPrice ? (oldPrice - newPrice) : (newPrice - oldPrice);
        uint256 impactBps = (diff * 10_000) / oldPrice;

        require(impactBps <= MAX_PRICE_IMPACT_BPS, "price impact too large");
    }

    function swapAForB(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "zero amountIn");

        (uint256 reserveA, uint256 reserveB) = _getReserves();
        require(reserveA > 0 && reserveB > 0, "empty pool");

        _checkMaxTrade(amountIn, reserveA);

        uint256 oldPrice = (reserveB * 1e18) / reserveA;

        uint256 k = reserveA * reserveB;
        uint256 newReserveA = reserveA + amountIn;
        uint256 newReserveB = k / newReserveA;

        require(newReserveB < reserveB, "no output");
        amountOut = reserveB - newReserveB;

        uint256 newPrice = (newReserveB * 1e18) / newReserveA;

        _checkPriceImpact(oldPrice, newPrice);

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

        _checkMaxTrade(amountIn, reserveB);

        uint256 oldPrice = (reserveB * 1e18) / reserveA; // price of A in B (same reference)

        uint256 k = reserveA * reserveB;
        uint256 newReserveB = reserveB + amountIn;
        uint256 newReserveA = k / newReserveB;

        require(newReserveA < reserveA, "no output");
        amountOut = reserveA - newReserveA;

        uint256 newPrice = (newReserveB * 1e18) / newReserveA;

        _checkPriceImpact(oldPrice, newPrice);

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
