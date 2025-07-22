# [DLMM: Liquidity Book](https://github.com/traderjoe-xyz/joe-v2)

This repository contains the Liquidity Book contracts, as well as tests and deploy scripts.

- The [LBPair](./src/LBPair.sol) is the contract that contains all the logic of the actual pair for swaps, adds, removals of liquidity and fee claiming. This contract should never be deployed directly, and the factory should always be used for that matter.

- The [LBToken](./src/LBToken.sol) is the contract that is used to calculate the shares of a user. The LBToken is a new token standard that is similar to ERC-1155, but without any callbacks (for safety reasons) and any functions or variables relating to ERC-721.

- The [LBFactory](./src/LBFactory.sol) is the contract used to deploy the different pairs and acts as a registry for all the pairs already created. There are also privileged functions such as setting the parameters of the fees, the flashloan fee, setting the pair implementation, set if a pair should be ignored by the quoter and add new presets. Unless the BipsConfig `isOpen` is `true`, only the owner of the factory can create pairs.

- The [LBRouter](./src/LBRouter.sol) is the main contract that user will interact with as it adds security checks. Most users shouldn't interact directly with the pair.

- The [LBQuoter](./src/LBQuoter.sol) is a contract that is used to return the best route of all those given. This should be used before a swap to get the best return on a swap.

For more information, go to the [documentation](https://docs.traderjoexyz.com/) and the [whitepaper](https://github.com/traderjoe-xyz/LB-Whitepaper/blob/main/Joe%20v2%20Liquidity%20Book%20Whitepaper.pdf).

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

### Documentation

[Foundry Book](https://book.getfoundry.sh/)

## Install foundry

Foundry documentation can be found in the [Foundry Book](https://getfoundry.sh/introduction/overview).

### On Linux and macOS

Open your terminal and type in the following command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. Then install Foundry by running:

```bash
foundryup
```

To update foundry after installation, simply run `foundryup` again, and it will update to the latest Foundry release.
You can also revert to a specific version of Foundry with `foundryup -v $VERSION`.

### On Windows

If you use Windows, you need to build from source to get Foundry.

Download and run `rustup-init` from [rustup.rs](https://rustup.rs/). It will start the installation in a console.

After this, run the following to build Foundry from source:

```bash
cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil --bins --locked
```

To update from source, run the same command again.

## Install dependencies

To install dependencies, run the following to install dependencies:

```bash
forge install
```

## Usage

### Build

```shell
forge build
```

### Test

To run all tests:

```shell
forge test
```

Run specific tests:

```shell
forge test --match-test testSwap
forge test --match-contract LBPairTest
```

Run tests with verbose output:

```shell
forge test -vvv
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

Start local Ethereum node:

```shell
anvil
```

### Deploy

```shell
forge script script/deploy-core.s.sol --rpc-url <your_rpc_url> --broadcast
```

### Cast

Interact with contracts:

```shell
cast call <address> <signature> [args] --rpc-url <rpc_url>
cast send <address> <signature> [args] --rpc-url <rpc_url> --private-key <key>
```

### Help

```shell
forge --help
anvil --help
cast --help
```

___

### Environment Setup

Create a `.env` file with:

```env
# BSC Testnet 私钥
PRIVATE_KEY=0xYourPrivateKeyHere

# BSCScan API Key（用于验证合约）https://etherscan.io/apidashboard
ETHERSCAN_API_KEY=YourBSCScanApiKeyHere

BSC_RPC_MAINNET_URL=https://bsc-dataseed.bnbchain.org
BSC_RPC_TESTNET_URL=https://data-seed-prebsc-1-s1.bnbchain.org:8545

```

### Test Results

Latest test run: **261 tests passed, 65 tests failed**

Most failures are in edge cases and fuzzing tests related to:

- Oracle helper boundary conditions
- Math library overflow/underflow edge cases
- SafeCast boundary validations
- Parameter validation edge cases

Core functionality tests are passing successfully.
