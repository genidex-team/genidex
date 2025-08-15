const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const geniDexHelper = require('../helpers/genidex.h');
const Market = require('../helpers/market.h');
const ordersHelper = require('../helpers/orders.h');
const data = require('../helpers/data');
const {utils} = require('genidex-sdk')
const config = require('../config/config');
const sdk = config.genidexSDK;
var marketId = 1;
var market, price, quantity;
var owner, upgrader, pauser, operator, referrer, user, user2, user3;
var genidex, geniDexAddress;

describe("GeniDex - Pause Functionality", function () {

    before(async () => {
        await geniDexHelper.init();
        await ordersHelper.init();
        market = await sdk.markets.getMarket(marketId);
        console.table(market);

        [owner, upgrader, pauser, operator, referrer, user, user2, user3] = await ethers.getSigners();
        genidex = await geniDexHelper.getContract();
        // genidex = await geniDexHelper.upgrade();
        // genidex = await geniDexHelper.deploy();
        // geniDexAddress = genidex.target;
        price = utils.parseBaseUnit(0.1);
        quantity = utils.parseBaseUnit(100);

        await ensureUnpaused(genidex, pauser);

    });

    it("Should allow owner to pause and unpause", async () => {
        // Pause
        await expect(sdk.pause(pauser))
            .to.emit(genidex, "Paused")
            .withArgs(pauser.address);

        // Unpause
        await expect(sdk.unpause(pauser))
            .to.emit(genidex, "Unpaused")
            .withArgs(pauser.address);
    });
    it("Should NOT allow non-owner to pause", async () => {
        await expect(sdk.pause(user))
            .to.be.revertedWithCustomError(genidex, "AccessManagedUnauthorized")
            .withArgs(user.address);
    });
    it("Should block placeBuyOrder and placeSellOrder when paused", async () => {
        await sdk.pause(pauser);
        await expect(
            buy(user, price, quantity, referrer.address)
        ).to.be.rejectedWith('EnforcedPause');
        await expect(
            sell(user, price, quantity, referrer.address)
        ).to.be.rejectedWith('EnforcedPause');
    });

    it("Should allow placeBuyOrder and placeSellOrder when not paused", async () => {
        await sdk.unpause(pauser); // in case default is paused
        await expect(
            sdk.balances.depositToken({
                signer: user,
                tokenAddress: market.quoteAddress,
                normAmount: utils.parseBaseUnit('1000')
            })
        ).to.not.be.reverted;
        await expect(
            sdk.balances.depositToken({
                signer: user,
                tokenAddress: market.baseAddress,
                normAmount: utils.parseBaseUnit('1000')
            })
        ).to.not.be.reverted;

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
        await sdk.unpause(signer);
    }
}