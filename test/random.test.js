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

        expect(typeof result).to.equal("boolean");
    });
});