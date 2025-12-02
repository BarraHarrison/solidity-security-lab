import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("Reentrancy Vulnerability Lab", function () {
    async function deployReentrancyFixture() {
        const [deployer, user, attackerEOA] = await ethers.getSigners();

        const VulnerableBank = await ethers.getContractFactory("VulnerableBank");
        const FixedBank = await ethers.getContractFactory("FixedBank");
        const Attacker = await ethers.getContractFactory("Attacker");

        const vulnerableBank = await VulnerableBank.deploy();
        await vulnerableBank.waitForDeployment();

        const fixedBank = await FixedBank.deploy();
        await fixedBank.waitForDeployment();

        const attackerAgainstVulnerable = await Attacker.connect(attackerEOA).deploy(
            await vulnerableBank.getAddress()
        );
        await attackerAgainstVulnerable.waitForDeployment();

        const attackerAgainstFixed = await Attacker.connect(attackerEOA).deploy(
            await fixedBank.getAddress()
        );
        await attackerAgainstFixed.waitForDeployment();

        const initialUserDeposit = ethers.parseEther("10");
        await vulnerableBank.connect(user).deposit({ value: initialUserDeposit });
        await fixedBank.connect(user).deposit({ value: initialUserDeposit });

        return {
            deployer,
            user,
            attackerEOA,
            vulnerableBank,
            fixedBank,
            attackerAgainstVulnerable,
            attackerAgainstFixed,
            initialUserDeposit,
        };
    }

    it("allows attacker to drain the VulnerableBank using reentrancy", async function () {
        const {
            attackerEOA,
            vulnerableBank,
            attackerAgainstVulnerable,
        } = await deployReentrancyFixture();

        const bankAddress = await vulnerableBank.getAddress();
        const attackerContractAddress = await attackerAgainstVulnerable.getAddress();

        const bankBalanceBefore = await ethers.provider.getBalance(bankAddress);
        expect(bankBalanceBefore).to.equal(ethers.parseEther("10"));

        const attackDeposit = ethers.parseEther("1");
        await attackerAgainstVulnerable
            .connect(attackerEOA)
            .attack({ value: attackDeposit });

        const bankBalanceAfter = await ethers.provider.getBalance(bankAddress);
        const attackerContractBalance = await ethers.provider.getBalance(
            attackerContractAddress
        );

        expect(bankBalanceAfter).to.equal(0n);

        expect(attackerContractBalance).to.be.greaterThanOrEqual(
            ethers.parseEther("10")
        );
    });

    it("blocks the same attack against FixedBank", async function () {
        const {
            attackerEOA,
            fixedBank,
            attackerAgainstFixed,
        } = await deployReentrancyFixture();

        const bankAddress = await fixedBank.getAddress();
        const attackerContractAddress = await attackerAgainstFixed.getAddress();

        const bankBalanceBefore = await ethers.provider.getBalance(bankAddress);
        expect(bankBalanceBefore).to.equal(ethers.parseEther("10"));

        const attackDeposit = ethers.parseEther("1");

        await expect(
            attackerAgainstFixed.connect(attackerEOA).attack({ value: attackDeposit })
        ).to.be.reverted;


        const bankBalanceAfter = await ethers.provider.getBalance(bankAddress);
        const attackerContractBalance = await ethers.provider.getBalance(
            attackerContractAddress
        );

        expect(bankBalanceAfter).to.equal(bankBalanceBefore);
        expect(attackerContractBalance).to.equal(0n);

    });
});