#!/bin/bash

# Load .env
cd $(realpath $(dirname $0))
source ./functions.sh
load_env_file ../.env

# Check env
if [ -z "$ALCHEMY_API_KEY" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
  echo "❌ Missing ALCHEMY_API_KEY or ETHERSCAN_API_KEY in .env"
  exit 1
fi

# Fetch gas fees from Etherscan
echo "⛽ Fetching gas fee data from Etherscan..."
response=$(curl -s "https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=$ETHERSCAN_API_KEY")

if [ -z "$response" ]; then
  echo "❌ Failed to fetch gas fee data."
  exit 1
fi

# Parse values (in gwei)
safe_gas_price=$(echo "$response" | jq -r '.result.SafeGasPrice')
propose_gas_price=$(echo "$response" | jq -r '.result.ProposeGasPrice')
fast_gas_price=$(echo "$response" | jq -r '.result.FastGasPrice')

# Convert to wei
gas_price_wei=$(echo "$propose_gas_price * 1000000000" | bc | cut -d'.' -f1)
base_fee_wei=$(echo "$safe_gas_price * 1000000000" | bc | cut -d'.' -f1)

echo "🚀 Starting Anvil with:"
echo "   ➤ Base fee      : ${safe_gas_price} gwei"
echo "   ➤ Gas price     : ${propose_gas_price} gwei"

    # --block-time 1 \
    # --quiet
    # --no-mining \
    # --fork-url "https://mainnet.infura.io/v3/$INFURA_API_KEY" \
    # --gas-price 35000000000 \
    # --base-fee 30000000000 \
    # --initial-base-fee 30000000000 \

anvil \
    --fork-url "https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}" \
    --fork-block-number 22802033 \
    --chain-id 1 \
    --threads 8 \
    --memory-limit 1073741824 \
    --accounts 30 --balance 1000 \
    --base-fee "$base_fee_wei" \
    --gas-price "$gas_price_wei" \
    --gas-limit 30000000