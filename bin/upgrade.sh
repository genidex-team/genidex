#!/bin/bash

cd ..
NETWORK=$1

echo "";
echo "================= upgrade_genidex.js ================="
npx hardhat run scripts/upgrade_genidex.js --network $NETWORK
