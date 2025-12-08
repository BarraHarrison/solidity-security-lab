// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC20 interface for transfers and balances
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @notice Minimal oracle interface (VulnerableOracle)
interface IPriceOracle {
    /// @return price of 1 tokenA in terms of tokenB, scaled by 1e18
    function getPrice() external view returns (uint256);
}

contract LendingProtocol {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    IPriceOracle public immutable oracle;

    // Collateral factor scaled by 1e18 (e.g. 0.5e18 = 50%)
    uint256 public collateralFactor;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    constructor(
        address _tokenA,
        address _tokenB,
        address _oracle,
        uint256 _collateralFactor
    ) {
        require(_collateralFactor <= 1e18, "factor too high");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        oracle = IPriceOracle(_oracle);
        collateralFactor = _collateralFactor;
    }

    /// @notice User deposits tokenA as collateral
    function depositCollateral(uint256 amount) external {
        require(amount > 0, "zero amount");
        require(
            tokenA.transferFrom(msg.sender, address(this), amount),
            "transferFrom failed"
        );
        collateral[msg.sender] += amount;
    }

    /// @notice View: value of user's collateral in tokenB terms, using the oracle price
    function collateralValueInTokenB(address user) public view returns (uint256) {
        uint256 price = oracle.getPrice();
        uint256 userColl = collateral[user];
        if (userColl == 0) return 0;

        return (userColl * price) / 1e18;
    }

    /// @notice View: maximum borrowable tokenB for a user
    function maxBorrow(address user) public view returns (uint256) {
        uint256 value = collateralValueInTokenB(user);
        return (value * collateralFactor) / 1e18;
    }

    /// @notice View: remaining borrowing capacity
    function availableToBorrow(address user) public view returns (uint256) {
        uint256 limit = maxBorrow(user);
        if (debt[user] >= limit) return 0;
        return limit - debt[user];
    }

    /// @notice Borrow tokenB up to your oracle-based limit
    function borrow(uint256 amount) external {
        require(amount > 0, "zero borrow");
        uint256 available = availableToBorrow(msg.sender);
        require(amount <= available, "exceeds borrow limit");

        require(
            tokenB.balanceOf(address(this)) >= amount,
            "insufficient liquidity"
        );

        debt[msg.sender] += amount;
        require(tokenB.transfer(msg.sender, amount), "borrow transfer failed");
    }

    /// @notice Repay borrowed tokenB
    function repay(uint256 amount) external {
        require(amount > 0, "zero repay");
        require(debt[msg.sender] >= amount, "repay too much");

        require(
            tokenB.transferFrom(msg.sender, address(this), amount),
            "repay transferFrom failed"
        );
        debt[msg.sender] -= amount;
    }

    /// @notice Withdraw some collateral (no safety checks, also naive)
    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "zero withdraw");
        require(collateral[msg.sender] >= amount, "not enough collateral");

        collateral[msg.sender] -= amount;
        require(tokenA.transfer(msg.sender, amount), "withdraw transfer failed");
    }
}
