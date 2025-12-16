// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712SignatureVault is EIP712 {
    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;

    bytes32 public constant WITHDRAW_TYPEHASH =
        keccak256(
            "Withdraw(address to,uint256 amount,uint256 nonce)"
        );

    constructor() EIP712("EIP712SignatureVault", "1") {}

    receive() external payable {}

    function withdraw(
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(address(this).balance >= amount, "insufficient vault balance");
        require(nonce == nonces[to], "invalid nonce");

        bytes32 structHash = keccak256(
            abi.encode(
                WITHDRAW_TYPEHASH,
                to,
                amount,
                nonce
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);

        require(signer == to, "invalid signature");

        nonces[to]++;

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "eth transfer failed");
    }
}