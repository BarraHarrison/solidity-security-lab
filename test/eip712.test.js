import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("EIP-712 Signature Vault", function () {

    async function deployFixture() {
        const [owner, attacker] = await ethers.getSigners();

        const Vault = await ethers.getContractFactory("EIP712SignatureVault");
        const vault = await Vault.deploy();

        await owner.sendTransaction({
            to: vault.target,
            value: ethers.parseEther("5")
        });

        return { owner, attacker, vault };
    }

    it("allows a valid EIP-712 signed withdrawal", async function () {
        const { owner, vault } = await deployFixture();

        const amount = ethers.parseEther("1");
        const nonce = 0;

        const domain = {
            name: "EIP712SignatureVault",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: vault.target
        };

        const types = {
            Withdraw: [
                { name: "to", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "nonce", type: "uint256" }
            ]
        };

        const value = {
            to: owner.address,
            amount,
            nonce
        };

        const signature = await owner.signTypedData(domain, types, value);

        const balanceBefore = await ethers.provider.getBalance(owner.address);

        await vault.withdraw(owner.address, amount, nonce, signature);

        const balanceAfter = await ethers.provider.getBalance(owner.address);

        expect(balanceAfter).to.be.gt(balanceBefore);
    });

    it("prevents replaying the same signature", async function () {
        const { owner, vault } = await deployFixture();

        const amount = ethers.parseEther("1");
        const nonce = 0;

        const domain = {
            name: "EIP712SignatureVault",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: vault.target
        };

        const types = {
            Withdraw: [
                { name: "to", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "nonce", type: "uint256" }
            ]
        };

        const value = {
            to: owner.address,
            amount,
            nonce
        };

        const signature = await owner.signTypedData(domain, types, value);

        await vault.withdraw(owner.address, amount, nonce, signature);

        await expect(
            vault.withdraw(owner.address, amount, nonce, signature)
        ).to.be.revertedWith("invalid nonce");
    });

    it("rejects signatures if withdrawal data is modified", async function () {
        const { owner, vault } = await deployFixture();

        const amount = ethers.parseEther("1");
        const nonce = 0;

        const domain = {
            name: "EIP712SignatureVault",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: vault.target
        };

        const types = {
            Withdraw: [
                { name: "to", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "nonce", type: "uint256" }
            ]
        };

        const signedValue = {
            to: owner.address,
            amount,
            nonce
        };

        const signature = await owner.signTypedData(domain, types, signedValue);

        await expect(
            vault.withdraw(
                owner.address,
                ethers.parseEther("2"),
                nonce,
                signature
            )
        ).to.be.revertedWith("invalid signature");
    });
});
