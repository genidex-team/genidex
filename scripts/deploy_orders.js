
const fn = require('../helpers/functions');
const { ethers, upgrades } = require('hardhat');



async function main() {
  // const feeData = await ethers.provider.getFeeData();
  // console.log(feeData);
  
  var transaction;
  var rs;

  const Contract = await ethers.getContractFactory('Orders');
  console.log('Deploying Contract...');

  //localhost
  const [owner] = await ethers.getSigners();
  var address = owner.address;

  const contract = await Contract.deploy();
  // console.log(gas);
  console.log('contract deployed to:', contract.target);
  
  var price = ethers.parseEther("0.000000000000000001");
  var quantity = ethers.parseEther("1");
  transaction = await contract.placeBuyOrder(price, quantity);
  await fn.printGasUsed(transaction, 'placeBuyOrder');

  transaction = await contract.placeBuyOrder(price, quantity);
  await fn.printGasUsed(transaction, 'placeBuyOrder');

  transaction = await contract.placeBuyOrder(price, quantity);
  await fn.printGasUsed(transaction, 'placeBuyOrder');

  // for(var i=0; i<10000; i++){
  //   contract.placeBuyOrder(price, quantity).then((transaction)=>{
  //     fn.printGasUsed(transaction, 'placeBuyOrder');
  //   })
  // }

  // rs = await contract.getBuyOrders('OP_USD');
  // console.log(rs);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});