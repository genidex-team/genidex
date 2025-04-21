const { expect } = require("chai");
const { ethers } = require("hardhat");
const geniDexHelper = require('../helpers/genidex.h');
const Market = require('../helpers/market.h');
const ordersHelper = require('../helpers/orders.h');
const data = require('geni_data');

describe("Referral.sol - Unit Tests", function () {
    let genidex, geniDexAddress;
    let marketId = 1;
    let market, price, quantity;
    let owner, user, referrer, otherUser;

    before(async () => {
        [owner, referrer, user, otherUser] = await ethers.getSigners();

        // Deploy the main GeniDex contract
        genidex = await geniDexHelper.getContract();
        genidex = await geniDexHelper.deploy();
        geniDexAddress = genidex.target;

        // Prepare market info and values
        market = new Market(marketId);
        price = market.parsePrice(0.0001);
        quantity = market.parseQuantity(1);

        // Initialize helpers
        await geniDexHelper.init();
        await ordersHelper.init();
    });

    it("✅ should allow owner to set referral root", async () => {
        const referralRoot = data.testnetAirdrop.getReferralRoot();
        await genidex.connect(owner).setReferralRoot(referralRoot);
        const savedRoot = await genidex.referralRoot();
        expect(savedRoot).to.equal(root);
    });

    return;

    it("✅ Should assign referrer on user's first buy order", async () => {
        await placeBuy(user, price, quantity, referrer.address);
        const assigned = await genidex.userReferrer(user.address);
        expect(assigned).to.equal(referrer.address);
    });

    it("❌ Should not allow self-referral", async () => {
        await placeBuy(referrer, price, quantity, referrer.address);
        const assigned = await genidex.userReferrer(referrer.address);
        expect(assigned).to.equal(ethers.ZeroAddress);
    });

    it("❌ Should not override existing referrer", async () => {
        await placeBuy(user, price, quantity, referrer.address);
        const initial = await genidex.userReferrer(user.address);
        expect(initial).to.equal(referrer.address);

        // Attempt to override with a different address
        await placeBuy(user, price, quantity, otherUser.address);
        const after = await genidex.userReferrer(user.address);
        expect(after).to.equal(referrer.address); // Should not change
    });

    it("❌ Should not assign referrer if referrer is address(0)", async () => {
        await placeBuy(user, price, quantity, ethers.ZeroAddress);
        const assigned = await genidex.userReferrer(user.address);
        expect(assigned).to.equal(ethers.ZeroAddress);
    });

    it("✅ Should track referrals correctly", async () => {
        await placeBuy(user, price, quantity, referrer.address);
        const referral = await genidex.referrals(referrer.address, 0);
        expect(referral).to.equal(user.address);
    });

    it("✅ Should count total referrals correctly", async () => {
        await placeBuy(user, price, quantity, referrer.address);
        await placeBuy(otherUser, price, quantity, referrer.address);
        const count = await genidex.referralCount(referrer.address);
        expect(count).to.equal(2);
    });
});

/// 🛠 Helper functions
async function placeBuy(trader, price, quantity, referrer) {
    return await ordersHelper.placeBuyOrder(trader, 1, price, quantity, referrer);
}

async function placeSell(trader, price, quantity, referrer) {
    return await ordersHelper.placeSellOrder(trader, 1, price, quantity, referrer);
}
