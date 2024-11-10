const { expect } = require("chai");
const hre = require("hardhat");
const fs = require('fs');
const jsonFile = "./data/erc20.abi.json";
const erc20Abi = JSON.parse(fs.readFileSync('./data/erc20.abi.json'));
const orderbookAbi = JSON.parse(fs.readFileSync('./data/orderbook.abi.json'));

var owner, trader1, trader2;
var baseAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
var quoteAddress = '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';
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


        // it("Deployed", async ()=>{
            await updateAddresses();
            await deployToken1();
            await deployToken2();
            await deployGeniDex();
            // orderbookAddress = '0x75c5c58722F99e46eF7583A668D7Ca2841e89f60';
            // console.log(rs);
        // })

        // it("approve trader1", async ()=>{
            let baseToken = new ethers.Contract(baseAddress, erc20Abi, trader1);
            let amount = hre.ethers.parseEther("1000");
            let rs = await baseToken.approve(orderbookAddress, amount);
        // })

        // it("placeBuyOrder", async ()=>{
            var price = 2;
            var quantity = hre.ethers.parseEther("10");
            let geniDexContract = new ethers.Contract(orderbookAddress, orderbookAbi, trader1);
            //uint256 price, uint256 quantity, address baseToken, address quoteToken
            await geniDexContract.placeBuyOrder(price, quantity, baseAddress, quoteAddress);
            await geniDexContract.placeBuyOrder(price, quantity, baseAddress, quoteAddress);
            rs = await geniDexContract.getBidOrders();
            console.log(rs);
        // })

        // it("approve trader2", async ()=>{
            let quoteToken = new ethers.Contract(quoteAddress, erc20Abi, trader2);
            amount = hre.ethers.parseEther("1000");
            rs = await quoteToken.approve(orderbookAddress, amount);
        // })
        

        // it("placeSellOrder", async ()=>{
            var price = 2;
            var quantity = hre.ethers.parseEther("10");
            geniDexContract = new ethers.Contract(orderbookAddress, orderbookAbi, trader2);
            //uint256 price, uint256 quantity, address baseToken, address quoteToken
            await geniDexContract.placeSellOrder(price, quantity, baseAddress, quoteAddress);
            await geniDexContract.placeSellOrder(price, quantity, baseAddress, quoteAddress);
            // console.log(rs);
            rs = await geniDexContract.getAskOrders();
            console.log(rs);
            rs = await geniDexContract.getBidOrders();
            console.log(rs);
        // })

}


async function deployToken1(){
    const initialSupply = hre.ethers.parseEther("10000");
    const token1 = await hre.ethers.deployContract("TestToken", ['USDT Token', 'USDT', initialSupply]);
    await token1.waitForDeployment();
    console.log(
        `Token1 Deployed to ${token1.target}`
    );
    baseAddress = token1.target;
    const amount = hre.ethers.parseEther("1000");
    await token1.transfer(trader1, amount);
    await token1.transfer(trader2, amount);
    // await token1.transfer(trader2, amount, {from: trader1});
}

async function deployToken2(){
    const initialSupply = hre.ethers.parseEther("10000");
    const token2 = await hre.ethers.deployContract("Token2", ['OP Token', 'OP', initialSupply]);
    await token2.waitForDeployment();
    console.log(
        `Token2 Deployed to ${token2.target}`
    );
    quoteAddress = token2.target;
    const amount = hre.ethers.parseEther("1000");
    await token2.transfer(trader1, amount);
    await token2.transfer(trader2, amount);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});