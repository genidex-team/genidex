


async function main() {
    const GeniDex = await ethers.getContractFactory('GeniDex');
    console.log('Deploying GeniDex...');
  
    //localhost
    const [owner] = await ethers.getSigners();
    var address = owner.address;
    
    //sepolia
    // var address = '0xe33d4f5523c52413CF55045d2577728C7d41e0a9';
    // 
    const geniDex = await upgrades.deployProxy(GeniDex, [address], {kind: 'uups', initializer: 'initialize'});
    await geniDex.waitForDeployment();
    console.log(geniDex);
    console.log('GeniDex deployed to:', geniDex.target);

    //sepolia
  // let baseAddress = '0xb88658A3eCa6173D9b40AcD8F096955C8F13b835'; //'0x5FbDB2315678afecb367f032d93F642f64180aa3';
  // let quoteAddress = '0xB5a272b3813791Cf6974f123F08E039b5785525F'; //'0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';

  //localhost
  let baseAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
  let quoteAddress = '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';
  let marketSymbol = 'OP_USDT';
  let rs = await geniDex.addMarket(baseAddress, quoteAddress);
  console.log(rs);
  rs = await geniDex.getMarketSymbol();
  console.log('OP_USDT market', rs);
  //0x6F1216D1BFe15c98520CA1434FC1d9D57AC95321

  let price = 2;
  let quantity = hre.ethers.parseEther("1");
  rs = await geniDex.placeBuyOrder(price, quantity);
  console.log('placeBuyOrder', rs);

  
  const transaction = await geniDex.getBuyOrders(marketSymbol);
  // console.log('getBuyOrders', rs);
  // const transactionReceipt = await transaction.wait();
  const gasUsed = transaction.gasUsed;

  console.log(`Gas used: ${gasUsed}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});