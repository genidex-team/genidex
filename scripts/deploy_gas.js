
const { ethers, network } = require('hardhat');
const fn = require('../helpers/functions');
const fs = require('fs');
const data = require('../helpers/data');


const erc20Abi = JSON.parse(fs.readFileSync('./data/erc20.abi.json'));

var owner, trader1, trader2;
var baseAddress = data.get('opAddress');
var quoteAddress = data.get('usdtAddress');
var orderbookAddress = '';
var geniDexToken, baseToken;

async function updateAddresses(){
    const accounts = await ethers.getSigners();
    owner = accounts[0];
    trader1 = accounts[1];
    trader2 = accounts[2];
    console.log('owner', owner.address);
    console.log('trader1', trader1.address);
    console.log('trader2', trader2.address, "\n");
}

async function main() {
  await updateAddresses();
  // const feeData = await ethers.provider.getFeeData();
  // console.log(feeData);
  
  var transaction;
  var rs;

  const Gas = await ethers.getContractFactory('Gas');
  console.log('Deploying Gas...');

  //localhost
  const [owner] = await ethers.getSigners();
  var address = owner.address;

  const gas = await Gas.deploy();
  // console.log(gas);
  console.log('gas deployed to:', gas.target);
  
  /*
  transaction = await gas.externalFunction();
  await fn.printGasUsed(transaction, 'externalFunction');

  transaction = await gas.publicFunction();
  await fn.printGasUsed(transaction, 'publicFunction');

  transaction = await gas.arrayInput([1]);
  await fn.printGasUsed(transaction, 'arrayInput');

  let inputs = [];
  for(let i=1; i<100; i++){
    inputs.push(i);
  }

  transaction = await gas.arrayInput(inputs);
  await fn.printGasUsed(transaction, 'arrayInput');
  // console.log(transaction.data);

  transaction = await gas.withOneInput(1);
  await fn.printGasUsed(transaction, 'withOneInput');
  console.log(transaction.data);
  
  transaction = await gas.withAddressInput('0x5FbDB2315678afecb367f032d93F642f64180aa3');
  await fn.printGasUsed(transaction, 'withAddressInput');
  console.log(transaction.data);
  

  transaction = await gas.storeOneNumber(42);
  await fn.printGasUsed(transaction, 'storeOneNumber');

  transaction = await gas.storeOneAddress('0xdac17f958d2ee523a2206206994597c13d831ec7');
  await fn.printGasUsed(transaction, 'storeOneAddress');

  transaction = await gas.addNumberNumberToMap(10000000000000, 42);
  await fn.printGasUsed(transaction, 'addNumberNumberToMap');

  transaction = await gas.addUint32NumberToMap(1, 42);
  await fn.printGasUsed(transaction, 'addUint32NumberToMap');

  transaction = await gas.addStringNumberToMap('OP_USDT', 42);
  await fn.printGasUsed(transaction, 'addStringNumberToMap');

  transaction = await gas.readWriteNumberNumberMap(1);
  await fn.printGasUsed(transaction, 'readWriteNumberNumberMap');

  transaction = await gas.storeOneString('OP_USDT');
  await fn.printGasUsed(transaction, 'storeOneString');
  
  transaction = await gas.storeTwoNumbers(42, 24);
  await fn.printGasUsed(transaction, 'storeTwoNumbers');

  transaction = await gas.pushElementToArray(422222356);
  await fn.printGasUsed(transaction, 'pushElementToArray');

  transaction = await gas.pushElementToArray(422222356);
  await fn.printGasUsed(transaction, 'pushElementToArray');

  try{
    rs = await gas.maxUint256();
    console.log('maxUint256', rs);
  }catch(error){
    console.log(error)
  }

  console.log('maxUint8', await gas.maxUint8());
  console.log('maxUint16', await gas.maxUint16());
  console.log('maxUint32', await gas.maxUint32());
  


  let baseToken = new ethers.Contract(baseAddress, erc20Abi, trader1);
  let amount = ethers.parseEther("10000000");
  rs = await baseToken.approve(gas.target, amount);

  
  console.log('\n=======transferFrom=======');
  transaction = await gas.noTransferFrom(baseAddress, 100);
  await fn.printGasUsed(transaction, 'noTransferFrom');

  transaction = await gas.transferFrom(baseAddress, 0);
  await fn.printGasUsed(transaction, 'transferFrom n=0');
  let gasUsed0 = await fn.getGasUsed(transaction);

  transaction = await gas.transferFrom(baseAddress, 1);
  await fn.printGasUsed(transaction, 'transferFrom n=1');
  let gasUsed1 = await fn.getGasUsed(transaction);

  transaction = await gas.transferFrom(baseAddress, 10);
  await fn.printGasUsed(transaction, 'transferFrom n=10');
  let gasUsed10 = await fn.getGasUsed(transaction);

  let firstGasUsed = gasUsed1-gasUsed0;
  let firstGasUsedFormat = new Intl.NumberFormat("en").format(firstGasUsed);
  console.log('First transferFrom', firstGasUsedFormat.yellow, fn.gasToUSD(firstGasUsed).yellow, 'USD');

  let fromSecondGasUsed = (gasUsed10 - gasUsed1)/9n;
  let fromSecondGasUsedFormat = new Intl.NumberFormat("en").format(fromSecondGasUsed);
  console.log('From second transferFrom', fromSecondGasUsedFormat.yellow, fn.gasToUSD(fromSecondGasUsed).yellow, 'USD');
  
  

  //updateUint256
  console.log('\n=======updateUint256=======');
  transaction = await gas.updateUint256(0);
  await fn.printGasUsed(transaction, 'updateUint256 n=0');
  gasUsed0 = await fn.getGasUsed(transaction);

  transaction = await gas.updateUint256(1);
  await fn.printGasUsed(transaction, 'updateUint256 n=1');
  gasUsed1 = await fn.getGasUsed(transaction);

  transaction = await gas.updateUint256(10);
  await fn.printGasUsed(transaction, 'updateUint256 \t\t n=10');
  gasUsed10 = await fn.getGasUsed(transaction);

  transaction = await gas.updateUint256Memory(10);
  await fn.printGasUsed(transaction, 'updateUint256Memory \t n=10');
  
  firstGasUsed = gasUsed1-gasUsed0;
  firstGasUsedFormat = new Intl.NumberFormat("en").format(firstGasUsed);
  console.log('First updateUint256', firstGasUsedFormat.yellow, fn.gasToUSD(firstGasUsed).yellow, 'USD');
  
  fromSecondGasUsed = (gasUsed10 - gasUsed1)/9n;
  fromSecondGasUsedFormat = new Intl.NumberFormat("en").format(fromSecondGasUsed);
  console.log('From second updateUint256', fromSecondGasUsedFormat.yellow, fn.gasToUSD(fromSecondGasUsed).yellow, 'USD');


  
  rs = await gas.test();
  console.log('test', rs);
  // await fn.printGasUsed(transaction, 'test');
  */

  transaction = await gas.addOrder1();
  await fn.printGasUsed(transaction, 'addOrder1');

  transaction = await gas.addOrder2();
  await fn.printGasUsed(transaction, 'addOrder2');

  transaction = await gas.addOrder3();
  await fn.printGasUsed(transaction, 'addOrder3');
  
  transaction = await gas.readOrder1();
  await fn.printGasUsed(transaction, 'readOrder1');

  transaction = await gas.readOrder2();
  await fn.printGasUsed(transaction, 'readOrder2');

  transaction = await gas.readOrder3();
  await fn.printGasUsed(transaction, 'readOrder3');

  

  transaction = await gas.addBalance1();
  await fn.printGasUsed(transaction, '\naddBalance1');

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});