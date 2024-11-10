#!/bin/bash

cd ..
NETWORK=$1

echo "";
echo "================= deploy_genidex.js ================="
npx hardhat run scripts/deploy_genidex.js --network $NETWORK

echo "";echo "";
echo "================= deploy_tokens.js =================="
npx hardhat run scripts/deploy_tokens.js --network $NETWORK

echo "";echo "";
echo "================= add_markets.js ===================="
npx hardhat run scripts/add_markets.js --network $NETWORK

echo "";echo "";
echo "================= node src/init.js ===================="
cd ../genidex_nodejs && node src/init.js $NETWORK