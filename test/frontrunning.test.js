import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("Frontrunning Lab", function () {

    async function deployVulnerable() {
        const [owner, user, attacker] = await ethers.getSigners();

        const Vulnerable = await ethers.getContractFactory("GuessVulnerable");
        const vulnerable = await Vulnerable.deploy(7, { value: ethers.parseEther("1") });

        return { owner, user, attacker, vulnerable };
    }

    async function deploySecure() {
        const [owner, user, attacker] = await ethers.getSigners();

        const Secure = await ethers.getContractFactory("GuessSecure");
        const secure = await Secure.deploy({ value: ethers.parseEther("1") });

        return { owner, user, attacker, secure };
    }

    it("allows attacker to frontrun and steal reward in Vulnerable contract", async function () {
        const { vulnerable, user, attacker } = await deployVulnerable();

        const pendingTx = vulnerable.connect(user).guess(7);

        await vulnerable.connect(attacker).guess(7, {
            gasPrice: ethers.parseUnits("50", "gwei")
        });

        await pendingTx;

        const contractBalance = await ethers.provider.getBalance(vulnerable.getAddress());
        expect(contractBalance).to.equal(0n);
    });

    it("prevents frontrunning using commit–reveal", async function () {
        const { secure, user, attacker } = await deploySecure();

        const answer = 7;
        const userGuess = 7;
        const userSecret = 12345;

        const commitHash = ethers.keccak256(
            ethers.solidityPacked(["uint256", "uint256"], [userSecret, userGuess])
        );

        await secure.connect(user).commit(commitHash);

        const attackerGuess = 7;
        const attackerSecret = 99999;

        const attackerHash = ethers.keccak256(
            ethers.solidityPacked(["uint256", "uint256"], [attackerSecret, attackerGuess])
        );

        await secure.connect(attacker).commit(attackerHash);

        await secure.connect(user).reveal(userGuess, userSecret, answer);

        await expect(
            secure.connect(attacker).reveal(attackerGuess, attackerSecret, answer)
        ).to.be.revertedWith("bad reveal");

        const reward = await secure.rewardPool();
        expect(reward).to.equal(0n);

        expect(await secure.winner()).to.equal(user.address);
    });

});
