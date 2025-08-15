#!/bin/bash

NETWORK=$1

echo -e "\n\n================= geni_token ================="
cd ../geni_token && ./bin/init.sh $NETWORK


echo -e "\n\n================= genidex_contract: deploy ================="
cd ../genidex_contract && \
npx hardhat run scripts/access/deploy.access.manager.js --network $NETWORK && \
npx hardhat run scripts/diamond/deploy.diamond.js --network $NETWORK && \
npx hardhat run scripts/diamond/merge.abi.js --network $NETWORK && \


echo -e "\n\n================= genidex-sdk ================="
cd ../genidex-sdk && \
node ./bin/generate.data.cjs && npm run build && \
npx tsx scripts/access/set.function.roles.ts && \
npx tsx scripts/access/grant.roles.ts && \


echo -e "\n\n================= genidex_contract: add market ================="
cd ../genidex_contract && \
npx hardhat run scripts/diamond/list.tokens.js --network $NETWORK
npx hardhat run scripts/diamond/add.markets.js --network $NETWORK


echo -e "\n\n================= geni_rewarder - init  ===================="
cd ../geni_rewarder && ./bin/init.sh $NETWORK && \


echo -e "\n\n================= genidex_contract: set GeniRewarder ===================="
cd ../genidex_contract && \
npx hardhat run scripts/set.geni.rewarder.address.js --network $NETWORK && \
npx hardhat run scripts/impersonate.and.send.js --network $NETWORK


echo -e "\n\n================= geni_rewarder - contribute.js ===================="
cd ../geni_rewarder && \
npx hardhat run scripts/contribute.js --network $NETWORK