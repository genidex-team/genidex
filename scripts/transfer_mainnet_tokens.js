const { ethers, network } = require('hardhat');
const fs = require('fs');
const data = require('geni_data');

let rpc = data.getRPC(network.name);
const provider = new ethers.JsonRpcProvider(rpc);
const tokenFile = './data/mainnet_tokens.json';

const recipients = [];

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
