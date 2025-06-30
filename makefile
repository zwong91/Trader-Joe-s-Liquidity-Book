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


.PHONY: all build clean deploy verify pool whitelist wrap-bnb test


all: build
test:
	forge test -vvv

build:
	forge build

clean:
	forge clean

deploy:
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --broadcast --verify

verify:
	forge verify-contract --chain-id 97 --etherscan-api-key $(BSCSCAN_API_KEY)

pool:
	forge script $(POOL_SCRIPT):TestPoolScript --rpc-url $(RPC_URL) --broadcast

wrap-bnb:
	forge script $(WRAP_BNB_SCRIPT):WrapBNBScript --rpc-url $(RPC_URL) --broadcast

whitelist:
	forge script $(WHITELIST_SCRIPT):WhitelistQuoteAssetScript --rpc-url $(RPC_URL) --broadcast
