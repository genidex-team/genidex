
const { ethers, upgrades, network } = require('hardhat');
const {GeniDex, NetworkName} = require("genidex-sdk");
const {Admin} = require("genidex-sdk/admin")
const { io } = require("socket.io-client");
const data = require('geni_data');

const apiSocket = io("http://localhost:3000/", {
    path: "/socket/",
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 5000
});

class Config{

    genidexSDK = new GeniDex();
    adminSDK;

    async init(){
        const rpc = data.getRPC(network.name);
        await this.genidexSDK.connect(network.name, rpc);
        this.adminSDK = new Admin(this.genidexSDK);
    }

}

const config = new Config();
async function main(){
    await config.init();
}
main();
module.exports = config;