import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("Oracle Manipulation Lab", function () {

    async function deployFixture() {
        const [deployer, attackerEOA, user] = await ethers.getSigners();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        const tokenA = await MockERC20ERC20.deploy(
            "TokenA",
            "TKA",
            depositor.address,
            ethers.parseUnits("100000")
        );

        const tokenB = await MockERC20ERC20.deploy(
            "TokenB",
            "TKB",
            depositor.address,
            ethers.parseUnits("100000")
        );


        const MockPool = await ethers.getContractFactory("MockPool");
        const pool = await MockPool.deploy(tokenA.target, tokenB.target);

        await tokenA.mint(pool.target, ethers.parseUnits("1000", 18));
        await tokenB.mint(pool.target, ethers.parseUnits("1000", 18));

        const VulnerableOracle = await ethers.getContractFactory("VulnerableOracle");
        const vulnerableOracle = await VulnerableOracle.deploy(
            tokenA.target,
            tokenB.target,
            pool.target
        );

        const LendingProtocol = await ethers.getContractFactory("LendingProtocol");
        const lendingVuln = await LendingProtocol.deploy(
            tokenA.target,
            tokenB.target,
            vulnerableOracle.target,
            ethers.parseUnits("0.5", 18)
        );

        await tokenB.mint(lendingVuln.target, ethers.parseUnits("5000", 18));

        const OracleAttacker = await ethers.getContractFactory("OracleAttacker");
        const attackerContract = await OracleAttacker.connect(attackerEOA).deploy(
            tokenA.target,
            tokenB.target,
            pool.target,
            lendingVuln.target
        );

        await tokenA.mint(attackerEOA.address, ethers.parseUnits("10", 18));
        await tokenB.mint(attackerEOA.address, ethers.parseUnits("2000", 18));

        await tokenA.connect(attackerEOA).approve(attackerContract.target, ethers.MaxUint256);
        await tokenB.connect(attackerEOA).approve(attackerContract.target, ethers.MaxUint256);


        const SafeOracle = await ethers.getContractFactory("SafeOracle");
        const safeOracle = await SafeOracle.deploy(
            ethers.parseUnits("1", 18)
        );

        const lendingSafe = await LendingProtocol.deploy(
            tokenA.target,
            tokenB.target,
            safeOracle.target,
            ethers.parseUnits("0.5", 18)
        );

        await tokenB.mint(lendingSafe.target, ethers.parseUnits("5000", 18));

        return {
            deployer,
            attackerEOA,
            user,
            tokenA, tokenB,
            pool,
            vulnerableOracle,
            lendingVuln,
            safeOracle,
            lendingSafe,
            attackerContract
        };
    }

    it("allows attacker to drain LendingProtocol using VulnerableOracle", async function () {
        const {
            attackerEOA,
            tokenA, tokenB,
            lendingVuln,
            attackerContract
        } = await deployFixture();

        const startBal = await tokenB.balanceOf(attackerEOA.address);

        const tokenBToPool = ethers.parseUnits("1500", 18);
        const collateralA = ethers.parseUnits("5", 18);

        await attackerContract.connect(attackerEOA).attack(
            tokenBToPool,
            collateralA
        );

        const afterBorrow = await tokenB.balanceOf(attackerContract.target);

        expect(afterBorrow).to.be.gt(ethers.parseUnits("2000", 18));
    });

    it("prevents oracle manipulation when using SafeOracle", async function () {
        const {
            attackerEOA,
            tokenA, tokenB,
            lendingSafe,
            safeOracle,
            attackerContract,
            pool
        } = await deployFixture();

        await safeOracle.setPrice(ethers.parseUnits("1", 18));


        const tokenBToPool = ethers.parseUnits("1500", 18);
        const collateralA = ethers.parseUnits("5", 18);

        await tokenB.connect(attackerEOA).transfer(pool.target, tokenBToPool);

        await tokenA.connect(attackerEOA).transfer(attackerContract.target, collateralA);

        const available = await lendingSafe.availableToBorrow(attackerContract.target);

        expect(available).to.be.lt(ethers.parseUnits("20", 18));

        await expect(
            lendingSafe.borrow(ethers.parseUnits("2000", 18))
        ).to.be.revertedWith("exceeds borrow limit");
    });
});