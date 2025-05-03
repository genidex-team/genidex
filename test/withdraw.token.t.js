// test/withdrawToken.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/tokens.h');
const tokenWalletHelper = require('../helpers/token.wallet.h');

const ONE_E18 = ethers.parseUnits("1", 18);
const to18 = (amount, dec) =>                 // helper: value -> 18-dec string
    ethers.parseUnits(amount.toString(), dec)   // raw in native decimals
    * (10n ** BigInt(18 - dec));          // normalise to 18

describe("GeniDex::withdrawToken", async () => {
    let geniDexContract, usdc, dai;
    let owner, trader1;
    let usdcDecimals = 6;
    let daiDecimals = 18;

    before(async ()=>{
        
    })

    beforeEach(async () => {
        // geniDexContract = await geniDexHelper.deploy();
        geniDexContract = await geniDexHelper.upgrade();
        // geniDexContract = await geniDexHelper.getContract();
        await tokenWalletHelper.init();
        await geniDexHelper.init();
        console.log('geniDex address', geniDexContract.target);

        [owner, trader1] = await ethers.getSigners();

        // ── deploy two mock tokens ──
        [usdc, token] = await tokenHelper.deploy('USD Coin', 'USDC', usdcDecimals);
        [dai, token] = await tokenHelper.deploy('Dai Stablecoin', 'DAI', daiDecimals);

        // mint to trader1
        await usdc.connect(trader1).mint(); // 1 000 USDC
        await dai.connect(trader1).mint();

        // list tokens (decimals only; price etc. not needed for tests)
        await geniDexContract.connect(owner).addMarket(usdc.target, dai.target);

        // trader1 approves vault
        await usdc.connect(trader1).approve(geniDexContract.target, ethers.MaxUint256);
        await dai.connect(trader1).approve(geniDexContract.target, ethers.MaxUint256);
    });

    it("deposits & withdraws exact amount (6-dec token)", async () => {
        let depositAmount = ethers.parseEther('100');
        await tokenWalletHelper.deposit(usdc.target, trader1, "50");
        await tokenWalletHelper.deposit(usdc.target, trader1, "50");

        // internal balance updated?
        expect(await tokenWalletHelper.getGeniDexBalance('trader1', usdc.target, trader1))
            .to.equal(depositAmount);

        // withdraw 40 USDC = 40 * 1e18
        const withdrawAmount = ethers.parseEther('40');
        const trader1BalBefore = await usdc.balanceOf(trader1.address);

        const tx = await geniDexContract.connect(trader1)
            .withdrawToken(usdc.target, withdrawAmount);
        // return;
        // event check
        await expect(tx)
            .to.emit(geniDexContract, "Withdrawal")
            .withArgs(trader1.address, usdc.target, withdrawAmount);

        // on-chain balance returned
        const trader1BalAfter = await usdc.balanceOf(trader1.address);
        expect(trader1BalAfter - trader1BalBefore).to.equal( ethers.parseUnits("40", usdcDecimals) );

        // internal balance decreased
        expect(await geniDexContract.balances(trader1.address, usdc.target))
            .to.equal(depositAmount - withdrawAmount);
    });

    it("reverts if user withdraws more than balance", async () => {
        const norm = ethers.parseEther("1")
        await geniDexContract.connect(trader1).depositToken(usdc.target, norm);

        await expect(
            geniDexContract.connect(trader1).withdrawToken(usdc.target, norm * 2n)
        ).to.be.revertedWithCustomError(geniDexContract, 'InsufficientBalance')
            .withArgs('BL55', norm, norm*2n);
    });

    // return;
    it("reverts for fee-on-transfer tokens", async () => {
        // deploy a fee token that burns 1 %
        const FeeToken = await ethers.getContractFactory("FeeToken");
        const feeTok = await FeeToken.deploy("Burner", "BRN", 18, 1000);
        await feeTok.mint(trader1.address, ethers.parseEther("100"));
        await geniDexContract.connect(owner).addMarket(feeTok.target, usdc.target);
        await feeTok.connect(trader1).approve(geniDexContract.target, ethers.MaxUint256);

        // trader1 deposits 10 BRN (works because deposit rejects mismatch)
        const strAmount = "100";
        const normAmount = ethers.parseEther(strAmount);
        // const tx = await geniDexContract.connect(trader1).depositToken(feeTok.target, normAmount);
        const tx = await tokenWalletHelper.deposit(feeTok.target, trader1, strAmount)

        const feeOnTransfer = normAmount/100n;
        const normReceived = normAmount - feeOnTransfer;
        await expect(tx)
            .to.emit(geniDexContract, "Deposit")
            .withArgs(trader1.address, feeTok.target, normReceived);

        expect(await tokenWalletHelper.getGeniDexBalance('trader1', feeTok.target, trader1))
            .to.equal(normReceived);

        // withdraw normAmount => revert
        await expect(
            geniDexContract.connect(trader1).withdrawToken(feeTok.target, normAmount)
        ).to.be.revertedWithCustomError(geniDexContract, 'InsufficientBalance')
        .withArgs('BL55', normReceived, normAmount);

        // withdraw normAmount - fee => OK
        await expect(
            geniDexContract.connect(trader1).withdrawToken(feeTok.target, normReceived)
        ).to.emit(geniDexContract, "Withdrawal")
        .withArgs(trader1.address, feeTok.target, normReceived);
    });
});