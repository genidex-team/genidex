const { ethers } = require("hardhat");
const erc20Abi = require('../data/erc20.abi.json');

async function main() {
  const provider = ethers.provider;

  await test();
//   const snapshotId = await provider.send("evm_snapshot", []);
//   console.log("Snapshot ID:", snapshotId);

  await provider.send("evm_revert", ["0x4e"]);
  console.log("Reverted to snapshot");
}

async function test(){
    const USDT_ADDRESS = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58";
    const signer = await ethers.getSigners();
    // const usdt = await ethers.getContractAt("IERC20", USDT_ADDRESS);
    const usdt = new ethers.Contract(USDT_ADDRESS, erc20Abi, signer[0]);
    // console.log(usdt);
    // return;
    const balance = await usdt.balanceOf('0x70997970C51812dc3A010C7d01b50e0d17dc79C8');
    console.log(
        ethers.formatUnits(balance, await usdt.decimals()).yellow
    );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });