import { expect } from "chai";
import hardhat from "hardhat";
const { ethers } = hardhat;

describe("Oracle Manipulation Lab", function () {
    async function deployFixture() {
        const [deployer, attackerEOA, user] = await ethers.getSigners();
        const depositor = user;

        const MockERC20 = await ethers.getContractFactory("MockERC20");

        const tokenA = await MockERC20.deploy(
            "TokenA",
            "TKA",
            depositor.address,
            ethers.parseUnits("100000", 18)
        );

        const tokenB = await MockERC20.deploy(
            "TokenB",
            "TKB",
            depositor.address,
            ethers.parseUnits("100000", 18)
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

        await ethers.provider.send("hardhat_setBalance", [
            attackerContract.target,
            "0x1000000000000000000",
        ]);

        await ethers.provider.send("hardhat_impersonateAccount", [
            attackerContract.target,
        ]);

        const attackerContractSigner = await ethers.getSigner(attackerContract.target);

        await tokenA
            .connect(attackerContractSigner)
            .approve(lendingVuln.target, ethers.MaxUint256);


        await tokenA.mint(attackerEOA.address, ethers.parseUnits("10", 18));
        await tokenB.mint(attackerEOA.address, ethers.parseUnits("2000", 18));

        await tokenA
            .connect(attackerEOA)
            .approve(attackerContract.target, ethers.MaxUint256);
        await tokenB
            .connect(attackerEOA)
            .approve(attackerContract.target, ethers.MaxUint256);

        const SafeOracle = await ethers.getContractFactory("SafeOracle");
        const safeOracle = await SafeOracle.deploy(ethers.parseUnits("1", 18));

        const lendingSafe = await LendingProtocol.deploy(
            tokenA.target,
            tokenB.target,
            safeOracle.target,
            ethers.parseUnits("0.5", 18)
        );

        await tokenB.mint(lendingSafe.target, ethers.parseUnits("5000", 18));

        await tokenA
            .connect(attackerEOA)
            .approve(lendingSafe.target, ethers.MaxUint256);

        return {
            deployer,
            attackerEOA,
            user,
            depositor,
            tokenA,
            tokenB,
            pool,
            vulnerableOracle,
            lendingVuln,
            attackerContract,
            safeOracle,
            lendingSafe,
        };
    }

    it("allows attacker to drain LendingProtocol using VulnerableOracle", async function () {
        const {
            attackerEOA,
            tokenB,
            lendingVuln,
            attackerContract,
        } = await deployFixture();

        const startBal = await tokenB.balanceOf(attackerEOA.address);

        const tokenBToPool = ethers.parseUnits("1500", 18);
        const collateralA = ethers.parseUnits("5", 18);

        await attackerContract.connect(attackerEOA).attack(
            tokenBToPool,
            collateralA
        );

        const attackerContractBal = await tokenB.balanceOf(attackerContract.target);
        expect(attackerContractBal).to.be.gt(ethers.parseUnits("2000", 18));

        const protocolBal = await tokenB.balanceOf(lendingVuln.target);
        expect(protocolBal).to.be.lt(ethers.parseUnits("5000", 18));
    });

    it("prevents oracle manipulation when using SafeOracle", async function () {
        const {
            attackerEOA,
            tokenA,
            tokenB,
            pool,
            safeOracle,
            lendingSafe,
        } = await deployFixture();

        await safeOracle.setPrice(ethers.parseUnits("1", 18));

        const tokenBToPool = ethers.parseUnits("1500", 18);
        const collateralA = ethers.parseUnits("5", 18);

        await tokenB.connect(attackerEOA).transfer(pool.target, tokenBToPool);

        await lendingSafe
            .connect(attackerEOA)
            .depositCollateral(collateralA);

        const available = await lendingSafe.availableToBorrow(attackerEOA.address);

        expect(available).to.be.lt(ethers.parseUnits("20", 18));

        await expect(
            lendingSafe
                .connect(attackerEOA)
                .borrow(ethers.parseUnits("2000", 18))
        ).to.be.revertedWith("exceeds borrow limit");
    });
});
