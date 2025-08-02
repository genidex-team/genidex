

const { ethers, network } = require("hardhat");
const data = require('geni_data');
const {factory} = require('geni_helper');


// const proxyAddress = data.getGeniDexAddress(network.name)
// const proxySalt = data.getGeniDexSalt();
const proxySalt = data.randomBytes32();

async function main() {
    const GeniDexReader = await ethers.getContractFactory("GeniDexReader");
    const geniDexReader = await GeniDexReader.deploy();
    await geniDexReader.waitForDeployment();

    const [deployer] = await ethers.getSigners();
    const initialOwner = deployer.address;
    console.log(`\nNetwork : ${network.name}`);
    console.log(`Deployer: ${deployer.address}`);

    console.log({proxySalt})

    let initArgs = [initialOwner];
    const proxyAddress = await factory.deploy('GeniDex', proxySalt, initArgs, 'uups');
    console.log({proxyAddress, network: network.name});
    data.setGeniDexAddress(network.name, proxyAddress)

    const GeniDex = await ethers.getContractFactory("GeniDex");
    const geniDexContract = new ethers.Contract(proxyAddress, GeniDex.interface, deployer);
    await geniDexContract.setReader(geniDexReader.target);
    const view = new ethers.Contract(proxyAddress, geniDexReader.interface, ethers.provider);
    const readerAddress = await view.getReader();
    console.log({readerAddress});
    console.log({readerAddress: geniDexReader.target});

}

main()
    .then(() => process.exit(0))
    .catch((e) => { console.error(e); process.exit(1); });
