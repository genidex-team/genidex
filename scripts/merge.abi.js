const path = require("path");
// const {mergeABI} = require('./libraries/diamond.js');
const {mergeAbi, toMinimalAbi} = require('./libraries/merge.abi.h.js');

function getArtifactFile(contract){
  if(contract=='GeniDex'){
    return path.join(__dirname, '../artifacts/contracts/' + contract + '.sol/' + contract + '.json');
  }
  return path.join(__dirname, '../artifacts/contracts/facets/' + contract + '.sol/' + contract + '.json');
}

const contracts = [
  'GeniDex',
  'DiamondCutFacet',
  'DiamondLoupeFacet',
  'OwnershipFacet',
  'TokenFacet',
  'MarketFacet',
  'ReaderFacet'
]

var abi = [];
var artifactPaths = [];

for (let i in contracts) {
  const contract = contracts[i];
  const file = getArtifactFile(contract);
  artifactPaths.push(file);
}

const { iface } = mergeAbi({
  artifactPaths: artifactPaths,
  outputPath: path.join(__dirname, '../data/abis/genidex.full.abi.json')
});

toMinimalAbi(
  iface,
  path.join(__dirname, '../data/abis/genidex.abi.json')
)

// console.log(iface);

// mergeABI();