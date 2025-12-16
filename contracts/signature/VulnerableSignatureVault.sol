// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerableSignatureVault {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw(
        uint256 amount,
        bytes calldata signature
    ) external {
        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, amount)
        );

        bytes32 ethSignedMessageHash =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

        address signer = recoverSigner(
            ethSignedMessageHash,
            signature
        );

        require(signer == owner, "invalid signature");
        require(address(this).balance >= amount, "insufficient balance");

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        require(signature.length == 65, "bad sig length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }

    receive() external payable {}
}