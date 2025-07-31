

const { ethers, network } = require("hardhat");
const data = require('geni_data');
const {factory} = require('geni_helper');


// const proxyAddress = data.getGeniDexAddress(network.name)
const proxySalt = data.getGeniDexSalt();
// const proxySalt = data.randomBytes32();

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialOwner = deployer.address;
    console.log(`\nNetwork : ${network.name}`);
    console.log(`Deployer: ${deployer.address}`);

    console.log({proxySalt})

    let initArgs = [initialOwner];
    const proxyAddress = await factory.deploy('GeniDex', proxySalt, initArgs, 'uups');
    console.log({proxyAddress, network: network.name});
    data.setGeniDexAddress(network.name, proxyAddress)

}

main()
    .then(() => process.exit(0))
    .catch((e) => { console.error(e); process.exit(1); });
