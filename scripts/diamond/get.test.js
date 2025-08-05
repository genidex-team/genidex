
const { ethers, network } = require('hardhat')
const { getSelectors, FacetCutAction, formatFacets } = require('../libraries/diamond.js')
const diamondABI = require('../../data/abis/genidex.full.abi.json')
const data = require('geni_data');

const diamondAddr = data.getGeniDexAddress(network.name);

async function main(){
    // console.log(diamondABI);
    // process.exit();
    const [deployer, trader1, trader2] = await ethers.getSigners();
    const diamondContract = new ethers.Contract(diamondAddr, diamondABI, trader2)

    console.log('authority', await diamondContract.authority.staticCall() )

    const rs = await diamondContract.test.staticCall();
    console.log(rs);

    const tx = await diamondContract.test();
    const receipt = await tx.wait();
    console.log(receipt.hash);

    // const result = await diamondContract.getFunction("test").staticCall();
    // console.log(result);

    // const tx = await diamondContract.test();
    // await tx.wait();
}

main();
