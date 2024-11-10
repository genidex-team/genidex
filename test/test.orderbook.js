const { expect } = require("chai");
const hre = require("hardhat");
const fs = require('fs');
const jsonFile = "./data/erc20.abi.json";
const erc20Abi = JSON.parse(fs.readFileSync('./data/erc20.abi.json'));
const orderbookAbi = JSON.parse(fs.readFileSync('./data/orderbook.abi.json'));

var owner, trader1, trader2;
var baseAddress = '0xB35d6B774C8946239A4afdEBCDAB38355A8428Fe';
var quoteAddress = '0xBB954BA2BAccB54c5144a71eAf26b188F2cD5978';
var orderbookAddress = '';
var geniDexToken, baseToken;

async function updateAddresses(){
    const accounts = await ethers.getSigners();
    owner = accounts[0];
    trader1 = accounts[1];
    trader2 = accounts[2];
    console.log('owner', owner.address);
    console.log('trader1', trader1.address);
    console.log('trader2', trader2.address, "\n");
}

async function deployGeniDex(){
    const geniDex = await hre.ethers.deployContract("GeniDex");
    await geniDex.waitForDeployment();
    orderbookAddress = geniDex.target;
    console.log(
        `GeniDex deployed to ${orderbookAddress}`
    );
}

async function placeBuyOrder(){

}

async function main() {

    describe("GeniDex", async function() {

        it("Deployed", async ()=>{
            await updateAddresses();

            await deployGeniDex();
            // orderbookAddress = '0x75c5c58722F99e46eF7583A668D7Ca2841e89f60';
            // console.log(rs);
        })

        it("approve trader1", async ()=>{
            let baseToken = new ethers.Contract(baseAddress, erc20Abi, trader1);
            let amount = hre.ethers.parseEther("1000");
            let rs = await baseToken.approve(orderbookAddress, amount);
        })

        it("placeBuyOrder", async ()=>{
            var price = 2;
            var quantity = hre.ethers.parseEther("10");
            let geniDexContract = new ethers.Contract(orderbookAddress, orderbookAbi, trader1);
            //uint256 price, uint256 quantity, address baseToken, address quoteToken
            await geniDexContract.placeBuyOrder(price, quantity, baseAddress, quoteAddress);
            await geniDexContract.placeBuyOrder(price, quantity, baseAddress, quoteAddress);
            let rs = await geniDexContract.getBidOrders();
            console.log(rs);
        })

        it("approve trader2", async ()=>{
            let quoteToken = new ethers.Contract(quoteAddress, erc20Abi, trader2);
            let amount = hre.ethers.parseEther("1000");
            let rs = await quoteToken.approve(orderbookAddress, amount);
        })
        

        it("placeSellOrder", async ()=>{
            var price = 2;
            var quantity = hre.ethers.parseEther("10");
            let geniDexContract = new ethers.Contract(orderbookAddress, orderbookAbi, trader2);
            //uint256 price, uint256 quantity, address baseToken, address quoteToken
            await geniDexContract.placeSellOrder(price, quantity, baseAddress, quoteAddress);
            await geniDexContract.placeSellOrder(price, quantity, baseAddress, quoteAddress);
            // console.log(rs);
            let rs = await geniDexContract.getAskOrders();
            console.log(rs);
            rs = await geniDexContract.getBidOrders();
            console.log(rs);
        })


    });
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});