import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("Overflow & Underflow Lab", function () {

    async function deployFixture() {
        const [owner, user] = await ethers.getSigners();

        const Vulnerable = await ethers.getContractFactory("VulnerableToken");
        const vulnerable = await Vulnerable.deploy();

        const Safe = await ethers.getContractFactory("SafeToken");
        const safe = await Safe.deploy();

        return { owner, user, vulnerable, safe };
    }

    it("demonstrates underflow in VulnerableToken", async function () {
        const { vulnerable, owner } = await deployFixture();

        expect(await vulnerable.balances(owner.address)).to.equal(1000);

        await expect(
            vulnerable.transfer(owner.address, 2000)
        ).to.be.revertedWith("Not enough balance");

        const hugeValue = 2n ** 256n - 500n;

        await vulnerable.connect(owner).mint(hugeValue);

        const bal = await vulnerable.balances(owner.address);
        expect(bal).to.be.lt(1000);
    });

    it("prevents underflow in SafeToken", async function () {
        const { safe, owner } = await deployFixture();

        expect(await safe.balances(owner.address)).to.equal(1000);

        await expect(
            safe.transfer(owner.address, 2000)
        ).to.be.reverted;
    });

    it("demonstrates mint overflow in VulnerableToken", async function () {
        const { vulnerable, owner } = await deployFixture();

        const maxBeforeOverflow = 2n ** 256n - 1n;

        await vulnerable.connect(owner).mint(maxBeforeOverflow);

        const supply = await vulnerable.totalSupply();
        expect(supply).to.be.lt(1000);
    });

    it("prevents mint overflow in SafeToken", async function () {
        const { safe, owner } = await deployFixture();

        const overflowValue = 2n ** 256n - 1n;

        await expect(
            safe.connect(owner).mint(overflowValue)
        ).to.be.reverted;
    });
});
