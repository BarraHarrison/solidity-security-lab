// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SafeOracle {
    address public owner;
    
    uint256 private _price;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    error NotOwner();

    constructor(uint256 initialPrice) {
        owner = msg.sender;
        _price = initialPrice;
        emit PriceUpdated(0, initialPrice);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Transfer oracle ownership to a new trusted account
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        address old = owner;
        owner = newOwner;
        emit OwnerTransferred(old, newOwner);
    }

    /// @notice Owner updates the price (e.g. from Chainlink/off-chain feed)
    /// @param newPrice Price of 1 tokenA in terms of tokenB, scaled by 1e18
    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "zero price");
        uint256 old = _price;
        _price = newPrice;
        emit PriceUpdated(old, newPrice);
    }

    /// @notice Consumer-facing function: returns latest price
    /// @return Price of 1 tokenA in terms of tokenB, scaled by 1e18
    function getPrice() external view returns (uint256) {
        return _price;
    }
}