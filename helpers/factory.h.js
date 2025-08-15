const { ethers, upgrades, network } = require("hardhat");
const { AbiCoder, solidityPacked } = require('ethers');
const data = require('geni_data');

const abiCoder = new AbiCoder();

class Factory {

    async getInitCode(contractName, owner) {
        const contract = await ethers.getContractFactory(contractName);
        return solidityPacked(
            ["bytes", "bytes"],
            [
                contract.bytecode,
                abiCoder.encode(["address"], [owner])
            ]
        );
    }

    async getInitCodeHash(contractName, owner){
        const initCode = await this.getInitCode(contractName, owner);
        const initCodeHash = ethers.keccak256(initCode);
        return initCodeHash;
    }

    async deployFromFactory(contractName, owner, saltHex) {
        const initCode = await this.getInitCode(contractName, owner);
        const initCodeHash = ethers.keccak256(initCode);
        const FACTORY_ADDRESS = data.getFactoryAddress(network.name);
        console.log({ FACTORY_ADDRESS });
        const predictedAddress = ethers.getCreate2Address(FACTORY_ADDRESS, saltHex, initCodeHash);

        if ((await ethers.provider.getCode(predictedAddress)).length === 2) {
            console.log("Deploying…");
            // const factory = await ethers.getContractAt("GeniDexFactory", FACTORY);

            const contractInterface = new ethers.Interface([
                "function deploy(bytes memory bytecode, bytes32 salt, address predictedAddr) external"
            ])
            const [deployer] = await ethers.getSigners();
            const factoryContract = new ethers.Contract(FACTORY_ADDRESS, contractInterface, deployer)

            const tx = await factoryContract.deploy(initCode, saltHex, predictedAddress);
            console.log(`deployFromFactory tx ${tx.hash}`);
            console.log('predictedAddress:', predictedAddress)
            await tx.wait();
        } else {
            const message = `Address already exists on-chain: ${predictedAddress}`
                + `\nPlease upgrade the contract or change the salt to generate a new address.\n`;
            throw new Error(message);
            // console.warn(message);
        }
        return predictedAddress;
    }
}

module.exports = new Factory();