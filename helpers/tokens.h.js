
const { ethers, run, network } = require('hardhat');
const path = require('path');
const fs = require('fs');
const fn = require('./functions');
const data = require('./data');
const erc20Abi = require('../data/erc20.abi.json');
var deployer, trader1, trader2;

class TokensHelper{

    constructor(){
        const defaultData = {};
        const filePath = path.join(__dirname, '../../genidex_nodejs/data/'+network.name+'_tokens.json');
        if (!fs.existsSync(filePath)) {
            fs.writeFileSync(filePath, JSON.stringify(defaultData, null, 2), 'utf8');
            this.tokens = defaultData;
        } else {
            const fileContent = fs.readFileSync(filePath, 'utf8');
            try {
                this.tokens = JSON.parse(fileContent);
            } catch (err) {
                this.tokens = defaultData;
            }
        }
    }

    async init(){
        [deployer, trader1, trader2] = await ethers.getSigners();
    }

    getToken(tokenAddress){
        return this.tokens[tokenAddress];
    }

    async deploy(name, symbol, decimals){
        [deployer, trader1, trader2] = await ethers.getSigners();
        // let amount = (2**(256-decimals)-1).toString();
        const initialSupply = ethers.parseUnits("20000000000", decimals);
        // const initialSupply = 2n**256n-1n;
        const contract = await ethers.deployContract("TestToken", [name, symbol, initialSupply.toString(), decimals]);
        await contract.waitForDeployment();
        console.log(`${symbol} Deployed to ${contract.target}`);
        
        let amount = ethers.parseUnits("10000000000", decimals);
        await contract.transfer(trader1, amount);
        await contract.transfer(trader2, amount);
        let token = {
            name: name,
            symbol: symbol,
            decimals: decimals,
            address: contract.target
        };
        return [contract, token];
    }

    async verify(address, name, symbol, decimals){
        const initialSupply = ethers.parseUnits("20000000000", decimals);
        await run(`verify:verify`, {
            address: address,
            constructorArguments: [name, symbol, initialSupply.toString(), decimals],
        });
    }

    async deployRandomBaseToken(){
        let decimals = fn.randomInt(0, 20);
        let name = 'Base'+decimals;
        let symbol = 'BA'+decimals;
        let [contract, token] = await this.deploy(name, symbol, decimals);
        return token;
    }

    async deployRandomQuoteToken(){
        let decimals = fn.randomInt(0, 20);
        let name = 'Quote'+decimals;
        let symbol = 'QU'+decimals;
        let [contract, token] = await this.deploy(name, symbol, decimals);
        return token;
    }

    async batchDeploy(numTokens){
        var arrTokens = [];
        for(let i=0; i<numTokens; i++){
            let name = 'Token'+i;
            let symbol = 'T'+i;
            let decimals = fn.randomInt(0, 20);
            console.log('Deploying ', symbol);
            let [contract, token] = await this.deploy(name, symbol, decimals);
            arrTokens.push(token);
            data.pushToMemory('tokens', token)
        }
        data.saveFile();
        return arrTokens;
    }

    async getTokenInfo(tokenAddress){
        let token = new ethers.Contract(tokenAddress, erc20Abi, trader1);
        let info = {
            address: tokenAddress,
            symbol: await token.symbol(),
            decimals: await token.decimals()
        }
        // console.log(info);
        return info;
    }



}

module.exports = new TokensHelper();
