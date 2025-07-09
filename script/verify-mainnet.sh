#!/bin/bash

# 主网合约验证脚本
echo "=== 开始验证 BSC 主网合约 ==="

# 从 deployments.json 读取合约地址
FACTORY_V2_1=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.factoryV2_1')
FACTORY_V2_2=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.factoryV2_2')
ROUTER_V2_1=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.routerV2_1')
ROUTER_V2_2=$(cat script/config/deployments.json | jq -r '.bnb_smart_chain.routerV2_2')

echo "📋 待验证的合约地址:"
echo "  Factory V2.1: $FACTORY_V2_1"
echo "  Factory V2.2: $FACTORY_V2_2"
echo "  Router V2.1: $ROUTER_V2_1"
echo "  Router V2.2: $ROUTER_V2_2"
echo ""

# 验证 Factory V2.1
echo "🔍 验证 Factory V2.1..."
make verify-mainnet ADDRESS=$FACTORY_V2_1 CONTRACT=src/LBFactory.sol:LBFactory
echo ""

# 验证 Factory V2.2
echo "🔍 验证 Factory V2.2..."
make verify-mainnet ADDRESS=$FACTORY_V2_2 CONTRACT=src/LBFactory.sol:LBFactory
echo ""

# 验证 Router V2.1
echo "🔍 验证 Router V2.1..."
make verify-mainnet ADDRESS=$ROUTER_V2_1 CONTRACT=src/LBRouter.sol:LBRouter
echo ""

# 验证 Router V2.2
echo "🔍 验证 Router V2.2..."
make verify-mainnet ADDRESS=$ROUTER_V2_2 CONTRACT=src/LBRouter.sol:LBRouter
echo ""

echo "✅ 所有合约验证完成！"
echo "📊 查看验证状态："
echo "  Factory V2.1: https://bscscan.com/address/$FACTORY_V2_1"
echo "  Factory V2.2: https://bscscan.com/address/$FACTORY_V2_2"
echo "  Router V2.1: https://bscscan.com/address/$ROUTER_V2_1"
echo "  Router V2.2: https://bscscan.com/address/$ROUTER_V2_2"
