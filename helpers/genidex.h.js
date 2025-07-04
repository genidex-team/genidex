
const { ethers, upgrades, network, run } = require('hardhat');
const path = require('path');
const fs = require('fs')
const fn = require('./functions');

const data = require('geni_data');

class GeniDexError extends Error {
    constructor(message, data) {
        super(message);
        this.name = "GeniDexError";
        this.data = data;
    }
}

var geniDexContract;

class GeniDexHelper{

    abiFiles = [
        path.join(__dirname, '../../genidex_nodejs/data/genidex_abi.json')//,
        // path.join(__dirname, '../../genidex_frontend/src/assets/')
    ];

    async init(){
        console.log('GeniDexHelper init');
        geniDexContract = await this.getContract();
        // this.percentageFee = await geniDexContract.percentageFee();
        // console.log(this.percentageFee);
        // this.feeDecimals = await geniDexContract.feeDecimals();
        // console.log(this.feeDecimals);
        
    }

    async deploy(){
        const GeniDex = await ethers.getContractFactory('GeniDex');
        console.log('Deploying GeniDex...');
        
        const [owner] = await ethers.getSigners();
        console.log('owner.address', owner.address)

        const geniDexContract = await upgrades.deployProxy(
            GeniDex,
            [owner.address],
            {kind: 'uups', initializer: 'initialize'}
        );
        await geniDexContract.waitForDeployment();
        console.log('\nGeniDex deployed to:', geniDexContract.target);
        data.setGeniDexAddress(network.name, geniDexContract.target);
        process.exit()

        await fn.printGasUsed(geniDexContract.deploymentTransaction(), 'deployProxy');
        if(network.name == 'sepolia' || network.name == 'op_sepolia'){
            await this.verify(geniDexContract.target);
        }
        const artifact = await hre.artifacts.readArtifact("GeniDex");
        // console.log(artifact.abi);
        this.writeABIFiles(artifact.abi);
        return geniDexContract;
    }

    async upgrade(){

        const proxyAddress = data.getGeniDexAddress(network.name);
        console.log(proxyAddress);
        const GeniDex = await ethers.getContractFactory('GeniDex');
        console.log('Upgrading GeniDex...');
        const geniDexContract = await upgrades.upgradeProxy(proxyAddress, GeniDex, {
            kind: 'uups'
        });
        data.setGeniDexAddress(network.name, geniDexContract.target);
        console.log('GeniDex upgraded. Proxy address:', geniDexContract.target);
        // console.log(geniDex.deployTransaction);
        await fn.printGasUsed(geniDexContract.deployTransaction, 'upgradeProxy');
        if(network.name == 'sepolia' || network.name == 'op_sepolia'){
            await this.verify(geniDexContract.target);
        }
        const artifact = await hre.artifacts.readArtifact("GeniDex");
        // console.log(artifact.abi);
        this.writeABIFiles(artifact.abi);
        return geniDexContract;
    }

    writeABIFiles(abi){
        for(var i in this.abiFiles){
            var file = this.abiFiles[i];
            fs.writeFileSync(file, JSON.stringify(abi, null, 2));
        }
    }

    async getContract(){
        const geniDexAddress = data.getGeniDexAddress(network.name);
        console.log('geniDexAddress', geniDexAddress)
        return await ethers.getContractAt('GeniDex', geniDexAddress);
    }

    async verify(address){
        try{
            await run(`verify:verify`, {
                address: address
            });
        }catch(error){
            if (error.message.toLowerCase().includes("already verified")) {
                console.log(`Contract at ${address} is already verified.`);
            } else {
                console.error("Verification failed:", error.message);
            }
        }
    }

    async getAllMarkets(){
        const geniDexContract = await this.getContract();
        var marketData = await geniDexContract.getAllMarkets();
        var markets = {};
        for(var i in marketData){
            let item = marketData[i];
            markets[item.id] = {
                id: parseInt(item.id),
                baseAddress: item.baseAddress,
                quoteAddress: item.quoteAddress,
                // baseDecimalsPower: parseInt(item.baseDecimalsPower)
            };
        }
        return markets;
    }

    async getAllTokens(){
        let setTokens = new Set();;
        let markets = await this.getAllMarkets();
        for(var i=0; i<markets.length; i++){
            let market = markets[i];
            setTokens.add(market.baseAddress);
            setTokens.add(market.quoteAddress);
        }
        return [...setTokens];
    }

    async fee(amount){
        return amount * this.percentageFee / this.feeDecimalsPower;
    }

    throwError(error) {
        const iface = geniDexContract.interface;
        const errorData = error?.data?.data || error?.data || error?.error?.data;
        if (!errorData){
            console.error(error);
            let name = error.code || error.message || error.shortMessage;
            throw new GeniDexError(name, error);
        };
        const decoded = iface.parseError(errorData);
        const args = {};
        for (let i = 0; i < decoded.fragment.inputs.length; i++) {
            const input = decoded.fragment.inputs[i];
            args[input.name] = decoded.args[i];
        }
        let result = {
            errorName: decoded.name,
            args
        };
        console.error(result);
        throw new GeniDexError(decoded.name, result);
    }

}

module.exports = new GeniDexHelper();