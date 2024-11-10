

const { ethers, network } = require('hardhat');
const erc20Abi = require('../data/erc20.abi.json');

const USDT_ADDRESS = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58"; // USDT address on Ethereum mainnet
const USDT_HOLDER = "0xF977814e90dA44bFA03b6295A0616a897441aceC"; // Holder address USDT on mainnet

// const {holders, tokens} = require('../data/'+network.name+'_data');

const hardhatAccount1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const contractABI = '[{"inputs":[{"internalType":"address","name":"_bridge","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"localToken","type":"address"},{"indexed":true,"internalType":"address","name":"remoteToken","type":"address"},{"indexed":false,"internalType":"address","name":"deployer","type":"address"}],"name":"OptimismMintableERC20Created","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"remoteToken","type":"address"},{"indexed":true,"internalType":"address","name":"localToken","type":"address"}],"name":"StandardL2TokenCreated","type":"event"},{"inputs":[],"name":"BRIDGE","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_remoteToken","type":"address"},{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"}],"name":"createOptimismMintableERC20","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_remoteToken","type":"address"},{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"}],"name":"createStandardL2Token","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]';

async function main() {
    const key = '580d5f3083472adf3615d2cec2871d233028ec06b53c36e1614449bda1e04ed2';
    const l1Address = '0x5589BB8228C07c4e15558875fAf2B859f678d129';
    const contractAddress = '0x4200000000000000000000000000000000000012';
    // const provider = new ethers.JsonRpcApiProvider('https://sepolia.optimism.io');

    // return;
    let provider = ethers.provider;
    const signer = new ethers.Wallet(key, provider);
    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    const adData = await contract.connect(signer).createOptimismMintableERC20(
        l1Address,
        "My Standard Demo Token",
        "L2TKN"
    );
    console.log(adData);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


// cast send 0x4200000000000000000000000000000000000012 
// "createOptimismMintableERC20(address,string,string)" 
// $TUTORIAL_L1_ERC20_ADDRESS "My Standard Demo Token" "L2TKN" 
// --private-key $PRIVATE_KEY --rpc-url $TUTORIAL_RPC_URL --json | 
// jq -r '.logs[0].topics[2]' | cast parse-bytes32-address

