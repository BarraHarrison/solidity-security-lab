// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SafeSignatureVault {
    address public immutable owner;

    mapping(address => uint256) public nonces;

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw(
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(nonce == nonces[recipient], "invalid nonce");
        require(address(this).balance >= amount, "insufficient vault balance");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                recipient,
                amount,
                nonce,
                address(this)
            )
        );

        address signer = _recoverSigner(messageHash, signature);
        require(signer == owner, "invalid signature");

        nonces[recipient]++;

        (bool ok, ) = recipient.call{value: amount}("");
        require(ok, "eth transfer failed");
    }

    function _recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 ethSignedMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(ethSignedMessage, v, r, s);
    }

    function _splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }
    }

    receive() external payable {}
}