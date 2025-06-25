#!/bin/bash

    # --block-time 1 \
    # --quiet
    # --no-mining \
anvil \
    --threads 8 \
    --memory-limit 1073741824 \
    --accounts 30 --balance 1000 \
    --block-base-fee-per-gas 0