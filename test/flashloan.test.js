import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("Flash Loan Attack Lab", function () {

    async function deployFixture() {
        const [deployer, attackerEOA, liquidityProvider] = await ethers.getSigners();

        const MockERC20 = await ethers.getContractFactory("MockERC20");

        const tokenA = await MockERC20.deploy(
            "TokenA",
            "TKA",
            liquidityProvider.address,
            ethers.parseUnits("100000", 18)
        );

        const tokenB = await MockERC20.deploy(
            "TokenB",
            "TKB",
            liquidityProvider.address,
            ethers.parseUnits("100000", 18)
        );

        const FlashLoanProvider = await ethers.getContractFactory("FlashLoanProvider");

        const flash = await FlashLoanProvider.deploy(tokenA.target);

        await tokenA.mint(flash.target, ethers.parseUnits("50000", 18));
        await tokenB.mint(flash.target, ethers.parseUnits("50000", 18));

        const VulnerableDEX = await ethers.getContractFactory("VulnerableDEX");
        const vulnDEX = await VulnerableDEX.deploy(tokenA.target, tokenB.target);

        await tokenA.mint(vulnDEX.target, ethers.parseUnits("10000", 18));
        await tokenB.mint(vulnDEX.target, ethers.parseUnits("10000", 18));

        const SafeDEX = await ethers.getContractFactory("SafeDEX");
        const safeDEX = await SafeDEX.deploy(tokenA.target, tokenB.target);

        await tokenA.mint(safeDEX.target, ethers.parseUnits("10000", 18));
        await tokenB.mint(safeDEX.target, ethers.parseUnits("10000", 18));

        const FlashLoanAttacker = await ethers.getContractFactory("FlashLoanAttacker");

        const attackerContract = await FlashLoanAttacker
            .connect(attackerEOA)
            .deploy(
                flash.target,
                tokenA.target,
                tokenB.target,
                vulnDEX.target
            );

        await tokenA.connect(attackerEOA).approve(attackerContract.target, ethers.MaxUint256);
        await tokenB.connect(attackerEOA).approve(attackerContract.target, ethers.MaxUint256);

        return {
            deployer,
            attackerEOA,
            liquidityProvider,
            tokenA,
            tokenB,
            flash,
            vulnDEX,
            safeDEX,
            attackerContract
        };
    }

    it("allows attacker to manipulate price using flash loan against VulnerableDEX", async function () {
        const {
            attackerEOA,
            tokenA,
            tokenB,
            vulnDEX,
            flash,
            attackerContract
        } = await deployFixture();

        const attackerStartB = await tokenB.balanceOf(attackerEOA.address);

        console.log("\n--- Attack vs VulnerableDEX Debug ---");
        console.log("Attacker starts with tokenB:", attackerStartB.toString());

        await attackerContract.connect(attackerEOA).startAttack(ethers.parseUnits("1000", 18));

        const attackerEndB = await tokenB.balanceOf(attackerEOA.address);
        const dexBalAfter = await tokenB.balanceOf(vulnDEX.target);

        console.log("Attacker ends with tokenB:", attackerEndB.toString());
        console.log("VulnerableDEX tokenB after attack:", dexBalAfter.toString());
        console.log("--- End Debug ---\n");

        expect(attackerEndB).to.be.gt(attackerStartB);

        expect(dexBalAfter).to.be.lt(ethers.parseUnits("10000", 18));
    });

    it("prevents flash-loan price manipulation when using SafeDEX", async function () {
        const {
            attackerEOA,
            tokenA,
            tokenB,
            safeDEX,
            flash,
            attackerContract
        } = await deployFixture();

        await attackerContract.setDEXTarget(safeDEX.target);

        const attackerStartB = await tokenB.balanceOf(attackerEOA.address);

        console.log("\n--- Attack vs SafeDEX Debug ---");
        console.log("Attacker starts with tokenB:", attackerStartB.toString());

        await expect(
            attackerContract.connect(attackerEOA).startAttack(ethers.parseUnits("1000", 18))
        ).to.be.reverted;

        const attackerEndB = await tokenB.balanceOf(attackerEOA.address);
        console.log("Attacker ends with tokenB:", attackerEndB.toString());
        console.log("--- End Debug ---\n");

        expect(attackerEndB).to.be.eq(attackerStartB);
    });

});
