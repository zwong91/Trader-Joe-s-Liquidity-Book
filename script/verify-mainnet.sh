#!/bin/bash

# 主网合约验证脚本
echo "=== 开始验证 BSC 主网合约 ==="

# 加载环境变量
source .env

# 从 deployments.json 读取合约地址
FACTORY_V2_1=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.factoryV2_1')
FACTORY_V2_2=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.factoryV2_2')
ROUTER_V2_1=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.routerV2_1')
ROUTER_V2_2=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.routerV2_2')
MULTISIG=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.multisig')
W_NATIVE=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.w_native')

# 构造函数参数
FACTORY_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,uint256)" $MULTISIG $MULTISIG 5000000000000)
ROUTER_V2_1_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address,address,address,address)" $FACTORY_V2_1 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 $W_NATIVE)
ROUTER_V2_2_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address,address,address,address)" $FACTORY_V2_2 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 $FACTORY_V2_1 $W_NATIVE)

echo "📋 待验证的合约地址:"
echo "  Factory V2.1: $FACTORY_V2_1"
echo "  Factory V2.2: $FACTORY_V2_2"
echo "  Router V2.1: $ROUTER_V2_1"
echo "  Router V2.2: $ROUTER_V2_2"
echo ""

# 验证 Factory V2.1
echo "🔍 验证 Factory V2.1..."
forge verify-contract $FACTORY_V2_1 src/LBFactory.sol:LBFactory --chain bsc --constructor-args ${FACTORY_CONSTRUCTOR_ARGS:2} --watch
echo ""

# 验证 Factory V2.2
echo "🔍 验证 Factory V2.2..."
forge verify-contract $FACTORY_V2_2 src/LBFactory.sol:LBFactory --chain bsc --constructor-args ${FACTORY_CONSTRUCTOR_ARGS:2} --watch
echo ""

# 验证 Router V2.1
echo "🔍 验证 Router V2.1..."
forge verify-contract $ROUTER_V2_1 src/LBRouter.sol:LBRouter --chain bsc --constructor-args ${ROUTER_V2_1_CONSTRUCTOR_ARGS:2} --watch
echo ""

# 验证 Router V2.2
echo "🔍 验证 Router V2.2..."
forge verify-contract $ROUTER_V2_2 src/LBRouter.sol:LBRouter --chain bsc --constructor-args ${ROUTER_V2_2_CONSTRUCTOR_ARGS:2} --watch
echo ""

echo "✅ 所有合约验证完成！"
echo "📊 查看验证状态："
echo "  Factory V2.1: https://bscscan.com/address/$FACTORY_V2_1"
echo "  Factory V2.2: https://bscscan.com/address/$FACTORY_V2_2"
echo "  Router V2.1: https://bscscan.com/address/$ROUTER_V2_1"
echo "  Router V2.2: https://bscscan.com/address/$ROUTER_V2_2"
