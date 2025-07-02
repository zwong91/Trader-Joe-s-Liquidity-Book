// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ILBFactory, LBFactory} from "src/LBFactory.sol";
import {ILBRouter, IJoeFactory, ILBLegacyFactory, ILBLegacyRouter, IWNATIVE, LBRouter} from "src/LBRouter.sol";
import {IERC20, LBPair} from "src/LBPair.sol";
import {LBQuoter} from "src/LBQuoter.sol";
import {BipsConfig} from "./config/bips-config.sol";

contract DeployAllVersions is Script {
    using stdJson for string;

    uint256 private constant FLASHLOAN_FEE = 5e12;

    struct Deployment {
        address factory_v1;
        address factory_v2;
        address factory_v2_1;
        address factory_v2_2;
        address router_v1;
        address router_v2;
        address router_v2_1;
        address router_v2_2;
        address quoter;
        address multisig;
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

            vm.createSelectFork(StdChains.getChain(chains[i]).rpcUrl);
            console.log("Deploying on chain: %s", chains[i]);
            // Start broadcasting as deployer for all actions
            vm.startBroadcast(deployer);

            // ===== V2.1 部署 =====
            LBFactory factoryV2_1 = new LBFactory(deployer, deployer, FLASHLOAN_FEE);
            LBPair pairImplV2_1 = new LBPair(factoryV2_1);
            LBRouter routerV2_1 = new LBRouter(
                factoryV2_1,
                IJoeFactory(address(0)),
                ILBLegacyFactory(address(0)),
                ILBLegacyRouter(address(0)),
                ILBFactory(address(0)),
                IWNATIVE(deployment.wNative)
            );
            factoryV2_1.setLBPairImplementation(address(pairImplV2_1));
            factoryV2_1.transferOwnership(deployment.multisig);

            // ===== V2.2 部署 =====
            LBFactory factoryV2_2 = new LBFactory(deployer, deployer, FLASHLOAN_FEE);
            LBPair pairImplV2_2 = new LBPair(factoryV2_2);
            LBRouter routerV2_2 = new LBRouter(
                factoryV2_2,
                IJoeFactory(address(0)),
                ILBLegacyFactory(address(0)),
                ILBLegacyRouter(address(0)),
                ILBFactory(address(factoryV2_1)),
                IWNATIVE(deployment.wNative)
            );
            factoryV2_2.setLBPairImplementation(address(pairImplV2_2));
            factoryV2_2.transferOwnership(deployment.multisig);

            // ===== Quoter 部署 =====
            LBQuoter quoter = new LBQuoter(
                address(0),
                address(0),
                address(factoryV2_1),
                address(factoryV2_2),
                address(0),
                address(routerV2_1),
                address(routerV2_2)
            );

            // ===== 配置 quote assets 和 presets（以 V2.2 为例，其他版本可类似配置）=====
            factoryV2_2.addQuoteAsset(IERC20(deployment.wNative));
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
            }
            
            vm.stopBroadcast();
            
            // ===== 输出部署信息 =====
            console.log("\n=== Deployment Summary ===");
            console.log("Chain: %s", chains[i]);
            console.log("Factory V2.1: %s", address(factoryV2_1));
            console.log("Factory V2.2: %s", address(factoryV2_2));
            console.log("Router V2.1: %s", address(routerV2_1));
            console.log("Router V2.2: %s", address(routerV2_2));
            console.log("Quoter: %s", address(quoter));
            console.log("PairImpl V2.1: %s", address(pairImplV2_1));
            console.log("PairImpl V2.2: %s", address(pairImplV2_2));
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
                rpcUrl: "https://bsc-testnet.infura.io/v3/402b910bd7e24d2a866ac48ab3741e75"
            })
        );
    }
}