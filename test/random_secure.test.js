import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("SafeRandom (Commit–Reveal RNG)", function () {

    async function deploySafe() {
        const [user, attacker] = await ethers.getSigners();

        const Safe = await ethers.getContractFactory("SafeRandom");
        const safe = await Safe.deploy();

        return { safe, user, attacker };
    }

    it("allows normal commit–reveal and generates a valid random number", async function () {
        const { safe, user } = await deploySafe();

        const secret = 12345;
        const commitHash = ethers.keccak256(
            ethers.solidityPacked(["address", "uint256"], [user.address, secret])
        );

        await safe.connect(user).commit(commitHash);

        const tx = await safe.connect(user).reveal(secret);
        const receipt = await tx.wait();

        const random = await safe.lastRandom();
        expect(random).to.be.at.least(0);
        expect(random).to.be.below(10);
    });

    it("prevents attacker from revealing without knowing the correct secret", async function () {
        const { safe, user, attacker } = await deploySafe();

        const realSecret = 12345;
        const badSecret = 99999;

        const commitHash = ethers.keccak256(
            ethers.solidityPacked(["address", "uint256"], [user.address, realSecret])
        );

        await safe.connect(user).commit(commitHash);

        await expect(
            safe.connect(attacker).reveal(badSecret)
        ).to.be.revertedWith("invalid reveal");
    });

    it("prevents attacker from predicting randomness by inspecting block data", async function () {
        const { safe, user, attacker } = await deploySafe();

        const secret = 11111;
        const commitHash = ethers.keccak256(
            ethers.solidityPacked(["address", "uint256"], [user.address, secret])
        );

        await safe.connect(user).commit(commitHash);

        const block = await ethers.provider.getBlock("latest");

        const attackerGuess = Number(
            BigInt(
                ethers.keccak256(
                    ethers.solidityPacked(["uint256", "bytes32"], [secret, block.hash])
                )
            ) % 10n
        );

        await safe.connect(user).reveal(secret);

        const realRandom = await safe.lastRandom();

        expect(attackerGuess).to.not.equal(realRandom);
    });

    it("prevents reusing the same commitment twice", async function () {
        const { safe, user } = await deploySafe();

        const secret = 12345;
        const commitHash = ethers.keccak256(
            ethers.solidityPacked(["address", "uint256"], [user.address, secret])
        );

        await safe.connect(user).commit(commitHash);
        await safe.connect(user).reveal(secret);

        await expect(
            safe.connect(user).reveal(secret)
        ).to.be.revertedWith("invalid reveal");
    });
});
