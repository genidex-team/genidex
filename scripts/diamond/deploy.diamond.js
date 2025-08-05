/* global ethers */
/* eslint prefer-const: "off" */

const { ethers, network } = require('hardhat')
const { getSelectors, FacetCutAction, mergeABI, getABI } = require('../libraries/diamond.js')
const data = require('geni_data');

async function main () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  const diamondInit = await deployDiamondInit();
  const facetCuts   = await deployFacets();
  const diamond     = await deployDiamond();

  const accessManager = data.getAccessManagerAddress(network.name);
  let functionCall = diamondInit.interface.encodeFunctionData('init', [accessManager])
  const diamondArgs = {
    init: diamondInit.target,
    initCalldata: functionCall
  }
  // console.log(facetCuts);
  const tx = await diamond.init(facetCuts, diamondArgs);
  const receipt = await tx.wait();
  console.log('hash', receipt.hash)
  return diamond.target
}

async function deployFacets(){
  // Deploy facets and set the `facetCuts` variable
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondCutFacet',
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'TokenFacet',
    'MarketFacet',
    // 'ReaderFacet'
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
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }
  return facetCuts;
}

async function deployDiamondInit(){
  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.waitForDeployment()
  console.log('DiamondInit deployed:', diamondInit.target)
  return diamondInit;
}

async function deployDiamond() {
  // deploy Diamond
  const Diamond = await ethers.getContractFactory('GeniDex')
  // const diamond = await Diamond.deploy(facetCuts, diamondArgs)
  const diamond = await Diamond.deploy()
  await diamond.waitForDeployment()
  console.log()
  console.log('Diamond deployed:', diamond.target)
  data.setGeniDexAddress(network.name, diamond.target);
  return diamond;
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

exports.deployDiamond = deployDiamond
