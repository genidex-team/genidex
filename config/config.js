
const { ethers, upgrades, network } = require('hardhat');
const {GeniDex, NetworkName} = require("genidex-sdk");
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

    async init(){
        const rpc = data.getRPC(network.name);
        await this.genidexSDK.connect(network.name, rpc);
    }

}

module.exports = new Config();