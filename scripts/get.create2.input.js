
// const {factory} = require('geni_helper');
// const helper = require('../helpers/helper');
const data = require('geni_data');

const factory = require('../helpers/factory.h');

async function main() {
    const [deployer] = await ethers.getSigners();
    const owner = await deployer.getAddress();
    const proxyInitCodeHash = await factory.getInitCodeHash('GeniDex', owner);
    const factoryAddress = data.getFactoryAddress(network.name);
    console.log({proxyInitCodeHash, factoryAddress});
}

main()
    .then(() => process.exit(0))
    .catch((e) => { console.error(e); process.exit(1); });