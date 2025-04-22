const { expect } = require("chai");
const { ethers } = require("hardhat");

const geniDexHelper = require("../helpers/genidex.h");
const Market = require("../helpers/market.h");
const ordersHelper = require("../helpers/orders.h");
const data = require("geni_data");

const marketId = 1;
let market, price, quantity;
let owner, user1, user2, referrer1, referrer2;

describe("Referral", function () {
    let genidex;
    const referralRoot = data.testnetAirdrop.getReferralRoot();

    before(async () => {
        [owner, user1, user2, referrer1, referrer2 ] = await ethers.getSigners();

        // genidex = await geniDexHelper.upgrade();
        genidex = await geniDexHelper.getContract();
        await geniDexHelper.init();
        await ordersHelper.init();

        market = new Market(marketId);
        price = market.parsePrice(0.00005);
        quantity = market.parseQuantity(2);
    });

    it("should allow the owner to unset referral root", async () => {
        let zeroRoot = ethers.ZeroHash;
        await genidex.connect(owner).setReferralRoot(zeroRoot);
        const storedRoot = await genidex.referralRoot();
        expect(storedRoot).to.equal(zeroRoot);
    });

    it("should revert if referral root is not set", async () => {
        const proof = data.testnetAirdrop.getReferralProof(user1.address);
        const referees = data.testnetAirdrop.getReferees(user1.address);
        await expect(
            genidex.connect(user1).migrateReferees(proof, referees)
        ).to.be.revertedWithCustomError(genidex, "ReferralRootNotSet");
    });

    it("should allow the owner to set referral root", async () => {
        await genidex.connect(owner).setReferralRoot(referralRoot);
        const storedRoot = await genidex.referralRoot();
        expect(storedRoot).to.equal(referralRoot);
    });

    it("should not allow non-owner to set referral root", async () => {
        await expect(
            genidex.connect(user1).setReferralRoot(referralRoot)
        ).to.be.revertedWithCustomError(genidex, 'OwnableUnauthorizedAccount');
    });

    it("should migrate referees with valid proof", async () => {
        const proof = data.testnetAirdrop.getReferralProof(user1.address);
        const referees = data.testnetAirdrop.getReferees(user1.address);
        // console.log('referees', referees);
        await genidex.connect(user1).migrateReferees(proof, referees);
        for (let i = 0; i < referees.length; i++) {
            const referee = referees[i];
            expect(await genidex.userReferrer(referee)).to.equal(user1.address);
        }
    });

    it("should revert on invalid proof", async () => {
        const fakeProof = data.testnetAirdrop.getReferralProof(user2.address);
        // console.log('fakeProof', fakeProof);
        const referees = data.testnetAirdrop.getReferees(user1.address);
        await expect(
            genidex.connect(user1).migrateReferees(fakeProof, referees)
        ).to.be.revertedWithCustomError(genidex, "InvalidProof");
    });

});
