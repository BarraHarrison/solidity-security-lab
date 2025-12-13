// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC20 interface compatible with your MockERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract FlashLoanProvider {
    IERC20 public immutable token;

    constructor(address _token) {
        require(_token != address(0), "zero token");
        token = IERC20(_token);
    }

    function flashLoan(
        uint256 amount,
        address borrower
        ) external {
        require(borrower != address(0), "zero borrower");

        uint256 balanceBefore = token.balanceOf(address(this));
        require(amount <= balanceBefore, "insufficient liquidity");

        require(token.transfer(borrower, amount), "flash transfer failed");

        (bool ok, bytes memory ret) = borrower.call(
            abi.encodeWithSignature("executeOnFlashLoan(uint256)", amount)
        );

        if (!ok) {
            if (ret.length > 0) {
                assembly {
                    revert(add(ret, 32), mload(ret))
                }
            }
            revert("flash loan callback failed");
        }



        uint256 balanceAfter = token.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "flash loan not repaid"
        );
    }
}