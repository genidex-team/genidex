#!/bin/bash

current_path=$(pwd)
source ./functions.sh
load_env_file ../.env

ganache  \
--wallet.mnemonic "test test test test test test test test test test test junk" \
--wallet.totalAccounts 20 \
--wallet.unlockedAccounts "0xF977814e90dA44bFA03b6295A0616a897441aceC" \
--wallet.unlockedAccounts "0xacD03D601e5bB1B275Bb94076fF46ED9D753435A" \
--wallet.unlockedAccounts "0xF6858Cb1AA854D7856afC5e7B2d160CE3ea63F5f" \
--wallet.unlockedAccounts "0x274d9E726844AB52E351e8F1272e7fc3f58B7E5F" \
--wallet.unlockedAccounts "0x1eED63EfBA5f81D95bfe37d82C8E736b974F477b" \
--wallet.unlockedAccounts "0x790b4086D106Eafd913e71843AED987eFE291c92" \
--fork.url https://arbitrum-mainnet.infura.io/v3/${INFURA_API_KEY} \
--fork.blockNumber 264733296 \
--db $current_path/../data/ganache_arb_mainnet \
--chain.chainId 42161 \
--server.port 9993

