// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {ILBFactory, LBFactory} from "src/LBFactory.sol";
import {ILBRouter, IJoeFactory, ILBLegacyFactory, ILBLegacyRouter, IWNATIVE, LBRouter} from "src/LBRouter.sol";
import {IERC20, LBPair} from "src/LBPair.sol";
import {LBQuoter} from "src/LBQuoter.sol";

import {BipsConfig} from "./config/bips-config.sol";

contract CoreDeployer is Script {
    using stdJson for string;

    uint256 private constant FLASHLOAN_FEE = 5e12;

    struct Deployment {
        address factoryV1;
        address factoryV2;
        address factoryV2_1;
        address multisig;
        address routerV1;
        address routerV2;
        address routerV2_1;
        address wNative;
    }

    string[] chains = ["bnb_smart_chain_testnet"];

    function setUp() public {
        _setupBSCTestnet();
    }

    function run() public {
        string memory json = vm.readFile("script/config/deployments.json");
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        console.log("Deployer address: %s", deployer);

        for (uint256 i = 0; i < chains.length; i++) {
            bytes memory rawDeploymentData = json.parseRaw(string(abi.encodePacked(".", chains[i])));
            Deployment memory deployment = abi.decode(rawDeploymentData, (Deployment));

            console.log("\nDeploying V2.2 on %s", chains[i]);

            vm.createSelectFork(StdChains.getChain(chains[i]).rpcUrl);

            vm.broadcast(deployer);
            LBFactory factoryV2_2 = new LBFactory(deployer, deployer, FLASHLOAN_FEE);
            console.log("LBFactory deployed -->", address(factoryV2_2));

            vm.broadcast(deployer);
            LBPair pairImplementation = new LBPair(factoryV2_2);
            console.log("LBPair implementation deployed -->", address(pairImplementation));

            vm.broadcast(deployer);
            LBRouter routerV2_2 = new LBRouter(
                factoryV2_2,
                IJoeFactory(deployment.factoryV1),
                ILBLegacyFactory(deployment.factoryV2),
                ILBLegacyRouter(deployment.routerV2),
                ILBFactory(deployment.factoryV2_1),
                IWNATIVE(deployment.wNative)
            );
            console.log("LBRouter deployed -->", address(routerV2_2));

            vm.startBroadcast(deployer);
            LBQuoter quoter = new LBQuoter(
                deployment.factoryV1,
                deployment.factoryV2,
                deployment.factoryV2_1,
                address(factoryV2_2),
                deployment.routerV2,
                deployment.routerV2_1,
                address(routerV2_2)
            );
            console.log("LBQuoter deployed -->", address(quoter));

            factoryV2_2.setLBPairImplementation(address(pairImplementation));
            console.log("LBPair implementation set on factoryV2_2");

            // 只有当 factoryV2 不是零地址时才尝试获取 quote assets
            if (deployment.factoryV2 != address(0)) {
                console.log("Setting up quote assets from existing factory...");
                uint256 quoteAssets = ILBLegacyFactory(deployment.factoryV2).getNumberOfQuoteAssets();
                for (uint256 j = 0; j < quoteAssets; j++) {
                    IERC20 quoteAsset = ILBLegacyFactory(deployment.factoryV2).getQuoteAsset(j);
                    factoryV2_2.addQuoteAsset(quoteAsset);
                    console.log("Quote asset whitelisted -->", address(quoteAsset));
                }
            } else {
                console.log("No existing factory found, setting up default quote assets...");
                // 为首次部署添加默认的 quote assets (WBNB)
                factoryV2_2.addQuoteAsset(IERC20(deployment.wNative));
                console.log("Default quote asset (WBNB) whitelisted -->", deployment.wNative);
                
                // 可以添加其他常用的代币作为 quote assets
                // 例如: USDT, USDC, BUSD 等 (如果需要的话)
            }

            // 设置预设配置
            console.log("Setting up factory presets...");
            uint256[] memory presetList = BipsConfig.getPresetList();
            for (uint256 j; j < presetList.length; j++) {
                BipsConfig.FactoryPreset memory preset = BipsConfig.getPreset(presetList[j]);
                factoryV2_2.setPreset(
                    preset.binStep,
                    preset.baseFactor,
                    preset.filterPeriod,
                    preset.decayPeriod,
                    preset.reductionFactor,
                    preset.variableFeeControl,
                    preset.protocolShare,
                    preset.maxVolatilityAccumulated,
                    preset.isOpen
                );
                console.log("Preset set for binStep -->", preset.binStep);
            }

            // 转移所有权给多签钱包
            factoryV2_2.transferOwnership(deployment.multisig);
            console.log("Factory ownership transferred to -->", deployment.multisig);
            
            vm.stopBroadcast();

            console.log("\n=== Deployment Summary ===");
            console.log("Chain: %s", chains[i]);
            console.log("Factory V2.2: %s", address(factoryV2_2));
            console.log("Router V2.2: %s", address(routerV2_2));
            console.log("Quoter: %s", address(quoter));
            console.log("Pair Implementation: %s", address(pairImplementation));
            console.log("Owner: %s", deployment.multisig);
            console.log("==========================\n");
        }
    }

    function _setupBSCTestnet() private {
        StdChains.setChain(
            "bnb_smart_chain_testnet",
            StdChains.ChainData({
                name: "BNB Smart Chain Testnet",
                chainId: 97,
                rpcUrl: "https://data-seed-prebsc-1-s1.bnbchain.org:8545"  // 使用固定的 RPC URL
            })
        );
    }
}
