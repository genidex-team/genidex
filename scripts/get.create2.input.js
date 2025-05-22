
const {factory} = require('geni_helper');
// const helper = require('../helpers/helper');
const data = require('geni_data');

async function main() {
    const proxyInitCodeHash = await factory.getProxyInitCodeHash();
    const factoryAddress = data.getFactoryAddress(network.name);
    console.log({proxyInitCodeHash, factoryAddress});
}

main()
    .then(() => process.exit(0))
    .catch((e) => { console.error(e); process.exit(1); });