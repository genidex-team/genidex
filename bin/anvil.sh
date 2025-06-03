#!/bin/bash

anvil \
    --block-time 1 \
    --disable-block-gas-limit \
    --threads 8 \
    --memory-limit 1073741824 \
    --accounts 20 --balance 1000 \
    --quiet