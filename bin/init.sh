#!/bin/bash


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

echo "";echo "";
echo "================= deploy geni_token ===================="
cd ../geni_token && ./bin/deploy.sh $NETWORK

echo "";echo "";
echo "================= init geni_rewarder ===================="
cd ../geni_rewarder && ./bin/init.sh $NETWORK

echo "";echo "";
echo "================= set.geni.rewarder.address.js ===================="
cd ../genidex_contract && npx hardhat run scripts/set.geni.rewarder.address.js --network $NETWORK

echo "";echo "";
echo "================= contribute.js ===================="
cd ../geni_rewarder && npx hardhat run scripts/contribute.js --network $NETWORK