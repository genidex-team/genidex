// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const { ethers, Signer } = require('hardhat');

const fs = require('fs');
const jsonFile = "./data/erc20.abi.json";
const erc20Abi = JSON.parse(fs.readFileSync(jsonFile));

var owner, trader1, trader2;
var baseAddress = '0xB35d6B774C8946239A4afdEBCDAB38355A8428Fe';
var quoteAddress = '0xBB954BA2BAccB54c5144a71eAf26b188F2cD5978';



async function updateAddresses(){
  const accounts = await ethers.getSigners();
  owner = accounts[0].address;
  trader1 = accounts[1].address;
  trader2 = accounts[2].address;
  // console.log(owner, trader1, trader2);
}

async function main() {

  const geniDex = await hre.ethers.deployContract("GeniDex");

  await geniDex.waitForDeployment();

  console.log(
    `GeniDex deployed to ${geniDex.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
