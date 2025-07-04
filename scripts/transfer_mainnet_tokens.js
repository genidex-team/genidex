const { ethers, network } = require('hardhat');
const fs = require('fs');
const { exit } = require('process');
const data = require('geni_data');

const provider = new ethers.JsonRpcProvider("http://localhost:8545");
const tokenFile = './data/mainnet_tokens.json';

const recipients = [];
// for (let i = 0; i < 10; i++) {
//     //   const wallet = ethers.Wallet.fromMnemonic("test test test test test test test test test test test junk", { path: `m/44'/60'/0'/0/${i}` });

//     recipients.push(wallet.address);
// }

const ERC20_ABI = [
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address to, uint amount) returns (bool)"
];

async function impersonateAndSend(tokenAddress, decimals, fromAccount) {

    await provider.send("anvil_impersonateAccount", [fromAccount]);
    await provider.send("anvil_setBalance", [fromAccount, "0x56BC75E2D63100000"]); // ~100 ETH

    const signer = await provider.getSigner(fromAccount);
    const token = new ethers.Contract(tokenAddress, ERC20_ABI, signer);
    const balance = await token.balanceOf(fromAccount);

    console.log(`Account ${fromAccount} has ${ethers.formatUnits(balance, decimals)} tokens of ${tokenAddress}`);

    if (balance > 0n) {
        const amountPerRecipient = balance / BigInt(recipients.length);
        for (const r of recipients) {
            const tx = await token.transfer(r, amountPerRecipient);
            await tx.wait();
            console.log(`Transferred ${ethers.formatUnits(amountPerRecipient, decimals)} to ${r}`);
        }
    }

    await provider.send("anvil_stopImpersonatingAccount", [fromAccount]);
}

async function main() {
    // const address = '0x4200000000000000000000000000000000000042';
    // const code = await provider.getCode(address);
    // console.log(code);
    // return;
    const strJson = fs.readFileSync(tokenFile, "utf8");
    const tokens = JSON.parse(strJson);
    const [deployer] = await ethers.getSigners();
    tokens.push({
        "symbol": "GENI",
        "token": data.getGeniTokenAddress(network.name),
        "decimals": 18,
        "accounts": [
            deployer.address
        ]
    })

    const signers = await ethers.getSigners();
    for (var i=0; i<10; i++) {
        const signer = signers[i];
        recipients.push(signer.address);
    }

    for (const { token, decimals, accounts } of tokens) {
        for (const acc of accounts) {
            try {
                await impersonateAndSend(token, decimals, acc);
                // console.log('token', token)
            } catch (e) {
                console.error(`Failed with ${acc} for token ${token}:`, e.message);
            }
        }
    }
}

main();
