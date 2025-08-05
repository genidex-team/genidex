/* global ethers */
/* eslint prefer-const: "off" */

const { ethers, network } = require('hardhat')
const { getSelectors, FacetCutAction, mergeABI, getABI } = require('../libraries/diamond.js')
const data = require('geni_data');
const abi = require('../../data/abis/genidex.full.abi.json');

async function main () {
  const accounts = await ethers.getSigners()
  const facetCuts   = await deployFacets();

  const genidexAddr = data.getGeniDexAddress(network.name);
  const diamond = await ethers.getContractAt(abi, genidexAddr);
  // const diamond = new ethers.Contract(genidexAddr, abi, accounts[0]);
  // console.log(diamond.interface); process.exit()

  // console.log(facetCuts); process.exit()

  const rs = await diamond.diamondCut.staticCall(facetCuts, ethers.ZeroAddress, '0x');
  console.log(rs);

  const tx = await diamond.diamondCut(facetCuts, ethers.ZeroAddress, '0x');
  const receipt = await tx.wait();
  console.log('hash', receipt.hash)
  return diamond.target
}

async function deployFacets(){
  // Deploy facets and set the `facetCuts` variable
  console.log('Deploying facets')
  const FacetNames = [
    'TokenFacet'
  ]
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.waitForDeployment()
    console.log(`${FacetName} deployed: ${facet.target}`)
    // console.log(facet.interface.fragments)

    facetCuts.push({
      facetAddress: ethers.ZeroAddress,
      action: FacetCutAction.Remove,
      functionSelectors: getSelectors(facet)
    })
  
    facetCuts.push({
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }
  return facetCuts;
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}
