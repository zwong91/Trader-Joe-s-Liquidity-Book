# Makefile

# 从 .env 文件中读取变量
ifeq (,$(wildcard .env))
$(error .env file not found)
endif

include .env
export

# 默认网络配置
RPC_TESTNET_URL ?= $(BSC_RPC_TESTNET_URL)
RPC_URL ?= $(BSC_RPC_MAINNET_URL)

# 脚本和日志文件
DEPLOY_SCRIPT := script/deploy-core.s.sol
POOL_SCRIPT := script/create-pool.s.sol
WRAP_BNB_SCRIPT := script/wrap-bnb.s.sol
WHITELIST_CHAPEL_SCRIPT := script/whitelist-quote-asset-chapel.s.sol
WHITELIST_SCRIPT := script/whitelist-quote-asset-mainnet.s.sol

.PHONY: all build coverage clean deploy verify pool whitelist wrap-bnb clone test test-unit test-integration test-no-fork

all: build

# 测试相关目标
test:
	forge test -vvv

# 仅运行单元测试（排除需要存档节点的集成测试）
test-unit:
	forge test --no-match-path "**/integration/*" -vv

# 运行集成测试（需要存档节点）
test-integration:
	forge test --match-path "**/integration/*" -vv

# 运行不需要 fork 的测试
test-no-fork:
	forge test --no-match-contract "*Fork*" --no-match-path "**/integration/*" -vv

# 快速测试（排除可能有问题的测试）
test-fast:
	forge test --no-match-contract "(LiquidityBinQuoterPriorityTest|LiquidityBinQuoterTest|LiquidityBinRouterForkTest)" -vv

coverage:
	forge coverage

build:
	forge build

clean:
	forge clean

local-deploy:
	forge script $(DEPLOY_SCRIPT) --rpc-url http://localhost:8545 --broadcast --interactives 1

deploy:
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_TESTNET_URL) --broadcast

# 验证合约 - 需要提供合约地址
# 使用方法: make verify ADDRESS=0x1234... CONTRACT=ContractName
verify:
	@if [ -z "$(ADDRESS)" ]; then \
		echo "错误: 请提供合约地址"; \
		echo "使用方法: make verify ADDRESS=0x1234... CONTRACT=ContractName"; \
		exit 1; \
	fi
	@if [ -z "$(CONTRACT)" ]; then \
		echo "验证合约: $(ADDRESS)"; \
		forge verify-contract --chain-id 97 --etherscan-api-key $(ETHERSCAN_API_KEY) $(ADDRESS); \
	else \
		echo "验证合约: $(ADDRESS) as $(CONTRACT)"; \
		forge verify-contract --chain-id 97 --etherscan-api-key $(ETHERSCAN_API_KEY) $(ADDRESS) $(CONTRACT); \
	fi

# 验证主网合约
verify-mainnet:
	@if [ -z "$(ADDRESS)" ]; then \
		echo "错误: 请提供合约地址"; \
		echo "使用方法: make verify-mainnet ADDRESS=0x1234... CONTRACT=ContractName"; \
		exit 1; \
	fi
	@if [ -z "$(CONTRACT)" ]; then \
		forge verify-contract --chain-id 56 --etherscan-api-key $(ETHERSCAN_API_KEY) $(ADDRESS); \
	else \
		forge verify-contract --chain-id 56 --etherscan-api-key $(ETHERSCAN_API_KEY) $(ADDRESS) $(CONTRACT); \
	fi

clone:
	forge clone --chain bsc-testnet --etherscan-api-key $(ETHERSCAN_API_KEY) 0x7D73A6eFB91C89502331b2137c2803408838218b DLMM

pool:
	forge script $(POOL_SCRIPT):TestPoolScript --rpc-url $(RPC_TESTNET_URL) --broadcast

wrap-bnb:
	forge script $(WRAP_BNB_SCRIPT):WrapBNBScript --rpc-url $(RPC_TESTNET_URL) --broadcast

whitelist-chapel:
	forge script $(WHITELIST_CHAPEL_SCRIPT):WhitelistQuoteAssetScript --rpc-url $(RPC_TESTNET_URL) --broadcast

whitelist:
	forge script $(WHITELIST_SCRIPT):WhitelistQuoteAssetScript --rpc-url $(RPC_URL) --broadcast

# 添加更多实用的目标
help:
	@echo "可用的 Makefile 目标:"
	@echo "  build          - 编译合约"
	@echo "  test           - 运行所有测试"
	@echo "  test-unit      - 仅运行单元测试"
	@echo "  test-fast      - 快速测试（排除集成测试）"
	@echo "  test-integration - 运行集成测试（需要存档节点）"
	@echo "  coverage       - 生成测试覆盖率报告"
	@echo "  clean          - 清理编译文件"
	@echo "  deploy         - 部署到测试网"
	@echo "  local-deploy   - 部署到本地网络"
	@echo "  verify         - 验证合约（需要 ADDRESS 和可选的 CONTRACT 参数）"
	@echo "  verify-mainnet - 验证主网合约"
	@echo "  pool           - 创建流动性池"
	@echo "  wrap-bnb       - 包装 BNB"
	@echo "  whitelist-chapel - 添加测试网白名单"
	@echo "  whitelist      - 添加主网白名单"
	@echo ""
	@echo "示例用法:"
	@echo "  make verify ADDRESS=0x1234567890123456789012345678901234567890"
	@echo "  make verify ADDRESS=0x1234... CONTRACT=src/MyContract.sol:MyContract"

# 检查环境变量
check-env:
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "错误: PRIVATE_KEY 未设置在 .env 文件中"; \
		exit 1; \
	fi
	@if [ -z "$(BSC_RPC_TESTNET_URL)" ]; then \
		echo "错误: BSC_RPC_TESTNET_URL 未设置在 .env 文件中"; \
		exit 1; \
	fi
	@echo "环境变量检查通过 ✓"

# 显示项目状态
status:
	@echo "=== 项目状态 ==="
	@echo "Foundry 版本: $$(forge --version | head -1)"
	@echo "Solidity 版本: 0.8.20"
	@echo "测试网 RPC: $(RPC_TESTNET_URL)"
	@echo "主网 RPC: $(RPC_URL)"
	@echo ""
	@echo "=== 编译状态 ==="
	@if [ -d "out" ]; then \
		echo "编译文件存在 ✓"; \
		echo "合约数量: $$(find out -name "*.json" | wc -l)"; \
	else \
		echo "需要编译 ⚠️"; \
	fi
