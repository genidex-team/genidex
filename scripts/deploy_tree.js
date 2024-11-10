
const fn = require('../helpers/functions');




async function main() {
  // const feeData = await ethers.provider.getFeeData();
  // console.log(feeData);
  
  var transaction;
  var rs;

  const Contract = await ethers.getContractFactory('TestTree');
  console.log('Deploying Contract...');

  //localhost
  const [owner] = await ethers.getSigners();
  var address = owner.address;

  const constract = await Contract.deploy();
  // console.log(gas);
  console.log('constract deployed to:', constract.target);
  
  for(var i=0; i<1000; i++){
    let price = fn.randomInt(1, 100);
    let quantity = fn.randomInt(1, 100);
    transaction = await constract.insert(price, quantity);
    await fn.printGasUsed(transaction, i+'. insertIntoTree');
  }
  
  transaction = await constract.empty();
  await fn.printGasUsed(transaction, 'empty');

  

  
  

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});