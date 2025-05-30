const { expect } = require("chai");
const { ethers } = require("hardhat");
const geniDexHelper = require('../helpers/genidex.h');
const Market = require('../helpers/market.h');
const ordersHelper = require('../helpers/orders.h');
const data = require('../helpers/data');

var marketId = 1;
var market, price, quantity;
var owner, trader1, trader2, trader3, referrer, user, otherUser, user3;

describe("Referral System", function () {
    let genidex, geniDexAddress;

    beforeEach(async () => {
        console.log('beforeEach');
        [owner, referrer, user, otherUser, user3] = await ethers.getSigners();

        genidex = await geniDexHelper.getContract();
        // genidex = await geniDexHelper.upgrade();
        // genidex = await geniDexHelper.deploy();
        geniDexAddress = genidex.target;

        market = new Market(marketId);
        price = market.parsePrice(0.000025);
        quantity = market.parseQuantity(1);
        await geniDexHelper.init();
        await ordersHelper.init();
    });

    it("should assign referrer on user's first buy order", async () => {
        await buy(user, price, quantity, referrer.address);
        const assignedReferrer = await genidex.userReferrer(user.address);

        console.log('\n');
        console.log(`🧪 User:               ${user.address}`);
        console.log(`👥 Referrer:           ${referrer.address}`);
        console.log(`👥 assignedReferrer:   ${assignedReferrer}\n\n`);

        expect(assignedReferrer).to.equal(referrer.address);
    });

    // return;
    it("should not allow self-referral", async () => {
        await buy(referrer, price, quantity, referrer.address);
        const assignedReferrer = await genidex.userReferrer(referrer.address);

        console.log('\n');
        console.log(`👥 ethers.ZeroAddress: ${ethers.ZeroAddress}`);
        console.log(`👥 assignedReferrer:   ${assignedReferrer}\n\n`);
        expect(assignedReferrer).to.equal(ethers.ZeroAddress);
    });

    // return;

    it("should not override existing referrer", async () => {
        await buy(user, price, quantity, referrer.address);

        const firstReferrer = await genidex.userReferrer(user.address);
        expect(firstReferrer).to.equal(referrer.address);

        // Try to override with otherUser
        await buy(user, price, quantity, otherUser.address);

        const updatedReferrer = await genidex.userReferrer(user.address);
        expect(updatedReferrer).to.equal(referrer.address); // Should not change
    });

    // return;

    it("should not assign referrer if address(0) is passed", async () => {
        await buy(referrer, price, quantity, ethers.ZeroAddress);
        const assignedReferrer = await genidex.userReferrer(referrer.address);
        expect(assignedReferrer).to.equal(ethers.ZeroAddress);
    });
});

async function buy(trader, price, quantity, referrer) {
    return await ordersHelper.placeBuyOrder(trader, marketId, price, quantity, referrer);
}

async function sell(trader, price, quantity, referrer) {
    return await ordersHelper.placeSellOrder(trader, marketId, price, quantity, referrer);
}