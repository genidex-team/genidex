const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const geniDexHelper = require('../helpers/genidex.h');
const Market = require('../helpers/market.h');
const ordersHelper = require('../helpers/orders.h');
const data = require('../helpers/data');

var marketId = 1;
var market, price, quantity;
var owner, trader1, trader2, trader3, referrer, user, otherUser, user3;
var genidex, geniDexAddress;

describe("GeniDex - Pause Functionality", function () {

    before(async () => {
        await geniDexHelper.init();
        await ordersHelper.init();

        [owner, referrer, user, otherUser, user3] = await ethers.getSigners();
        genidex = await geniDexHelper.getContract();
        // genidex = await geniDexHelper.upgrade();
        // genidex = await geniDexHelper.deploy();
        geniDexAddress = genidex.target;

        market = new Market(marketId);
        price = market.parsePrice(0.000025);
        quantity = market.parseQuantity(1);

        await ensureUnpaused(genidex, owner);

    });

    it("Should allow owner to pause and unpause", async () => {
        // Pause
        await expect(genidex.connect(owner).pause())
            .to.emit(genidex, "Paused")
            .withArgs(owner.address);

        // Unpause
        await expect(genidex.connect(owner).unpause())
            .to.emit(genidex, "Unpaused")
            .withArgs(owner.address);
    });

    it("Should NOT allow non-owner to pause", async () => {
        await expect(genidex.connect(user).pause())
            .to.be.revertedWithCustomError(genidex, "OwnableUnauthorizedAccount")
            .withArgs(user.address);
    });

    it("Should block placeBuyOrder and placeSellOrder when paused", async () => {
        await genidex.connect(owner).pause();
        await expect(
            buy(user, price, quantity, referrer.address)
        ).to.be.rejectedWith('EnforcedPause');
        await expect(
            sell(user, price, quantity, referrer.address)
        ).to.be.rejectedWith('EnforcedPause');
    });

    it("Should allow placeBuyOrder and placeSellOrder when not paused", async () => {
        await genidex.connect(owner).unpause(); // in case default is paused
        await expect(
            buy(user, price, quantity, referrer.address)
        ).to.not.be.reverted;
        await expect(
            sell(user, price, quantity, referrer.address)
        ).to.not.be.reverted;
    });

});

async function buy(trader, price, quantity, referrer) {
    return await ordersHelper.placeBuyOrder(trader, marketId, price, quantity, referrer);
}

async function sell(trader, price, quantity, referrer) {
    return await ordersHelper.placeSellOrder(trader, marketId, price, quantity, referrer);
}

async function ensureUnpaused(contract, signer) {
    const isPaused = await contract.paused();
    if (isPaused) {
        await contract.connect(signer).unpause();
    }
}