

const { ethers, network } = require('hardhat');
const erc20Abi = require('../data/erc20.abi.json');

const USDT_ADDRESS = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58"; // USDT address on Ethereum mainnet
const USDT_HOLDER = "0xF977814e90dA44bFA03b6295A0616a897441aceC"; // Holder address USDT on mainnet

const {holders, tokens} = require('../data/'+network.name+'_data');

const hardhatAccount1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";

async function main() {

    // let tokenAddress = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
    for(var i in tokens){
        var tokenAddress = tokens[i];
        for(var i in holders){
            let holderAddress = holders[i];
            let sent = await sendToken(holderAddress, tokenAddress);
            // if(sent==true){
            //     break;
            // }
        }
    }
}

async function sendToken(holderAddress, tokenAddress){
    console.log(holderAddress);

    const signer = await ethers.getSigner(holderAddress);
    const token = new ethers.Contract(tokenAddress, erc20Abi, signer);
    const symbol = await token.symbol();
    const decimals = await token.decimals();
    const balance = await token.balanceOf(holderAddress);
    console.log("balance", balance, ethers.formatUnits(balance, decimals), symbol);
    if(balance>0n){
        try{
            if(await ethers.provider.getBalance(await signer.getAddress())==0n){
                await sendETH(holderAddress);
            }
            const tx = await token.transfer(hardhatAccount1, balance);
            await tx.wait();
            console.log("Transferred", ethers.formatUnits(balance, decimals), symbol);
            return true;
        }catch(error){
            console.log(error);
        }
        
    }
    let balance1 = await token.balanceOf(hardhatAccount1);
    // console.log('\n', symbol, tokenAddress);
    // console.log("hardhatAccount1's balance", ethers.formatUnits(balance1, decimals), symbol);
}

async function sendETH(recipientAddress){
    const [sender, trader1] = await ethers.getSigners();
    // console.log("Sender balance before:", (await trader1.getBalance()).toString());
    const tx = {
        to: recipientAddress,
        value: ethers.parseEther("0.001")
    };
    const transaction = await trader1.sendTransaction(tx);
    // console.log("Transaction hash:", transaction.hash);
    await transaction.wait();
    // console.log("Sender balance after:", (await trader1.getBalance()).toString());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});