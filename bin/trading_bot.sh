#!/bin/bash

cd .. && \
nodemon \
--exec "npx hardhat run scripts/trading_bot.js \
--network geni" \
--watch scripts \
--watch helpers