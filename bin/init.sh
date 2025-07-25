#!/bin/bash


NETWORK=$1

echo "";
echo "================= geni_token/bin/init.sh  ================="
cd ../geni_token && ./bin/init.sh $NETWORK

echo "";
echo "================= genidex_contract - deploy.ether.js ================="
cd ../genidex_contract && npx hardhat run scripts/deploy.ether.js --network $NETWORK && \

cd ../genidex-sdk && node ./bin/generate.data.cjs && npm run build && \

# echo "";echo "";
# echo "================= genidex_contract - deploy_tokens.js =================="
# npx hardhat run scripts/deploy_tokens.js --network $NETWORK && \

echo "";echo "";
echo "================= genidex_contract - add_markets.js ===================="
cd ../genidex_contract && npx hardhat run scripts/add_markets.js --network $NETWORK && \

echo "";echo "";
echo "================= genidex_nodejs - src/init.js ===================="
cd ../genidex_nodejs && node src/init.js $NETWORK && \

echo "";echo "";
echo "================= geni_rewarder - init  ===================="
cd ../geni_rewarder && ./bin/init.sh $NETWORK && \

echo "";echo "";
echo "================= genidex_contract - set.geni.rewarder.address.js ===================="
cd ../genidex_contract && npx hardhat run scripts/set.geni.rewarder.address.js --network $NETWORK && \
npx hardhat run scripts/transfer_mainnet_tokens.js --network $NETWORK

echo "";echo "";
echo "================= geni_rewarder - contribute.js ===================="
cd ../geni_rewarder && npx hardhat run scripts/contribute.js --network $NETWORK