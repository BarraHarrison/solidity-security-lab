import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("Safe Signature Replay Protection Lab", function () {

    async function deployFixture() {
        const [owner, attacker] = await ethers.getSigners();

        const Vault = await ethers.getContractFactory("SafeSignatureVault");
        const vault = await Vault
            .connect(owner)
            .deploy({ value: ethers.parseEther("5") });

        return { owner, attacker, vault };
    }

    it("prevents replaying the same signature", async function () {
        const { owner, attacker, vault } = await deployFixture();

        const amount = ethers.parseEther("1");
        const nonce = 0;

        const messageHash = ethers.keccak256(
            ethers.solidityPacked(
                ["address", "uint256", "uint256", "address"],
                [attacker.address, amount, nonce, vault.target]
            )
        );

        const signature = await owner.signMessage(
            ethers.getBytes(messageHash)
        );

        const vaultStart = await ethers.provider.getBalance(vault.target);

        await vault.connect(attacker).withdraw(
            attacker.address,
            amount,
            nonce,
            signature
        );

        const vaultAfterFirst = await ethers.provider.getBalance(vault.target);
        expect(vaultAfterFirst).to.equal(vaultStart - amount);

        await expect(
            vault.connect(attacker).withdraw(
                attacker.address,
                amount,
                nonce,
                signature
            )
        ).to.be.revertedWith("invalid nonce");
    });
});
