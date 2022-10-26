# Introduction
The illiquidity of staked ETH may deter user participation and calls for an immediate solution. As a project dedicated to addressing the liquidity issue of staked assets, Stafi team hereby propose the rETH solution, which allows for Ethereum 2.0 liquid staking at ease.

# Design goals

### 1) Stakers
- Stakers will be able to participate in ETH Staking through the Staking Contract deployed on Ethereum 1.0 by StaFi, and one would only need as little as 0.01 ETH to start, or any amount at his own discretion, instead of committing a fixed amount of 32 ETH.
- Stakers are not required to run validator nodes nor spend time and costs maintaining them. StaFi’s Staking Contract (SC) deployed on Ethereum 1.0 will automatically match a staker’s ETH to “well-performing” validators that are in the “Available” state.

### 2) Validators
- StaFi will allocate staked ETH in SC to a batch of well-performing original validators, who would establish and maintain appropriate amounts of validator nodes to provide staking rewards to stakers net of fees.

### 3) Solving the Liquidity Dilemma for Both Stakers and Validators
- For a specific staker, whenever he stakes ETH to the SC, she will automatically receive a certain amount of rETH Tokens (ERC20 version) in return, which is a synthetic representation of her staked ETH balance and corresponding staking rewards. The rETH token may then be traded on a variety of trading venues, and can be used in other DeFi protocols.
- For validators, StaFi will initiate a Liquidity Program, through which they could also sell part of their ETH staked in the SC back to StaFi. Relevant details are specified in the Original Validator portion.

# Dependencies

Requires `nodejs` and `npm`.

# Compile

```
npm install
npm run compile
```

# Test

```
export ALCHEMY_API_KEY=xxxxxxxxxxxxxxxxxx

npm run test
```

# Show contract size

```
npm run size
```

# deploy

```
npx hardhat run deploy_test.js --network xxxxx
```

# verify in etherscan

```
npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
```

# Credits
Special thanks to these libraries which have been great references for developing eth2-staking

- https://github.com/ethereum/eth2.0-specs
- https://github.com/ethereum/eth2.0-deposit-cli
- https://github.com/rocket-pool/rocketpool
- https://github.com/ethereum/eth2.0-deposit