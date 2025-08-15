/* global ethers */
/* eslint prefer-const: "off" */
const path = require('path');
const fs = require('fs');
const { ethers, network } = require('hardhat')
const { getSelectors, FacetCutAction, getFacetNames } = require('../libraries/diamond.js')
const data = require('geni_data');
const factory = require('../../helpers/factory.h');
let deployer;

async function main() {
  [deployer] = await ethers.getSigners();

  const diamond = await deployDiamond();
  const diamondInit = await deployDiamondInit();
  const facetCuts = await deployFacets();

  const accessManager = data.getAccessManagerAddress(network.name);
  let functionCall = diamondInit.interface.encodeFunctionData('init', [accessManager])
  const diamondArgs = {
    init: diamondInit.target,
    initCalldata: functionCall
  }
  console.log('diamondInit.accessManager', accessManager);
  // console.log(facetCuts);
  await diamond.init.staticCall(facetCuts, diamondArgs);
  const tx = await diamond.init(facetCuts, diamondArgs);
  const receipt = await tx.wait();
  console.log('hash', receipt.hash)
  return diamond.target
}

async function deployFacets() {
  // Deploy facets and set the `facetCuts` variable
  console.log('Deploying facets')
  const FacetNames = getFacetNames();

  const AccessFacet = await ethers.getContractFactory('AccessFacet');
  const accessFacetSelectors = getSelectors(AccessFacet);
  // console.log(accessFacetSelectors); process.exit();

  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = []
  for (const FacetName of FacetNames) {
    // const accessSelectors = getSelectors(accessFacet);

    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.waitForDeployment()
    console.log(`${FacetName} deployed: ${facet.target}`)
    // console.log(facet.interface.fragments)
    const selectors = getSelectors(facet);
    if (FacetName != 'AccessFacet') {
      selectors.remove(accessFacetSelectors);
    }
    facetCuts.push({
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: selectors
    })
  }
  return facetCuts;
}

async function deployDiamondInit() {
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
  const salt = data.getGeniDexSalt();
  // const salt = data.randomBytes32();
  const owner = await deployer.getAddress();
  const genidexAddress = await factory.deployFromFactory('GeniDex', owner, salt)
  console.log('GeniDex deployed:', genidexAddress)
  data.setGeniDexAddress(network.name, genidexAddress);
  const diamond = ethers.getContractAt('GeniDex', genidexAddress, deployer);
  return diamond;
}

main();

exports.deployDiamond = deployDiamond
