
# Makefile

# 从 .env 文件中读取变量
ifeq (,$(wildcard .env))
$(error .env file not found)
endif

include .env
export

# 默认网络配置
RPC_URL ?= $(BSC_RPC_TESTNET_URL)

# 脚本和日志文件
DEPLOY_SCRIPT := script/deploy-core.s.sol
POOL_SCRIPT := script/create-pool.s.sol
WRAP_BNB_SCRIPT := script/wrap-bnb.s.sol
WHITELIST_SCRIPT := script/whitelist-quote-asset.s.sol


.PHONY: all build coverage clean deploy verify pool whitelist wrap-bnb clone test


all: build
test:
	forge test -vvv

coverage:
	forge coverage

build:
	forge build

clean:
	forge clean

local-deploy:
	forge script $(DEPLOY_SCRIPT) --fork-url http://localhost:8545 --broadcast --interactives 1

deploy:
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --broadcast

verify:
	forge verify-contract --chain-id 97 --etherscan-api-key $(ETHERSCAN_API_KEY)

clone:
	forge clone --chain bsc-testnet --etherscan-api-key $(ETHERSCAN_API_KEY) 0x7D73A6eFB91C89502331b2137c2803408838218b DLMM

pool:
	forge script $(POOL_SCRIPT):TestPoolScript --rpc-url $(RPC_URL) --broadcast

wrap-bnb:
	forge script $(WRAP_BNB_SCRIPT):WrapBNBScript --rpc-url $(RPC_URL) --broadcast

whitelist:
	forge script $(WHITELIST_SCRIPT):WhitelistQuoteAssetScript --rpc-url $(RPC_URL) --broadcast
