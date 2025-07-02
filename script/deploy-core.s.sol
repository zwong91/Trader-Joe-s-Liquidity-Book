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
        address factoryV2_1;
        address factoryV2_2;
        address multisig;
        address routerV2_1;
        address routerV2_2;
        address w_native;
    }

    struct DeployedContracts {
        LBFactory factoryV2_1;
        LBFactory factoryV2_2;
        LBPair pairImplV2_1;
        LBPair pairImplV2_2;
        LBRouter routerV2_1;
        LBRouter routerV2_2;
        LBQuoter quoter;
    }

    string[] chains = ["bnb_smart_chain_testnet"];

    function setUp() public {
        _setupBSCTestnet();
    }

    function run() public {
        string memory json = vm.readFile("script/config/deployments.json");

        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        console.log("=== LB Protocol Deployment ===");
        console.log("Deployer address: %s", deployer);
        console.log("Deployer balance: %s ETH", deployer.balance / 1e18);

        for (uint256 i = 0; i < chains.length; i++) {
            bytes memory rawDeploymentData = json.parseRaw(string(abi.encodePacked(".", chains[i])));
            Deployment memory deployment = abi.decode(rawDeploymentData, (Deployment));
            
            console.log("w_native: %s", deployment.w_native);
            console.log("multisig: %s", deployment.multisig);
            // Validate configuration
            require(deployment.w_native != address(0), "Invalid w_native address");
            require(deployment.multisig != address(0), "Invalid multisig address");

            vm.createSelectFork(StdChains.getChain(chains[i]).rpcUrl);
            console.log("\nDeploying on chain: %s (ID: %s)", chains[i], vm.toString(block.chainid));
            
            // Deploy all contracts
            DeployedContracts memory deployed = _deployContracts(deployer, deployment);
            
            // Configure contracts
            _configureContracts(deployed, deployment);
            
            // Transfer ownership
            _transferOwnership(deployed, deployment.multisig);
            
            // Verify deployments
            _verifyDeployments(deployed, deployment);
            
            // Print deployment summary
            _printDeploymentSummary(chains[i], deployed, deployment);
        }
    }

    function _deployContracts(address deployer, Deployment memory deployment) 
        private 
        returns (DeployedContracts memory deployed) 
    {
        console.log("\n--- Deploying Contracts ---");
        vm.startBroadcast(deployer);

        // Deploy V2.1 Factory and Pair Implementation
        console.log("Deploying Factory V2.1...");
        deployed.factoryV2_1 = new LBFactory(deployer, deployer, FLASHLOAN_FEE);
        require(address(deployed.factoryV2_1) != address(0), "Factory V2.1 deployment failed");
        console.log("Factory V2.1 deployed at: %s", address(deployed.factoryV2_1));

        console.log("Deploying Pair Implementation V2.1...");
        deployed.pairImplV2_1 = new LBPair(deployed.factoryV2_1);
        require(address(deployed.pairImplV2_1) != address(0), "Pair Implementation V2.1 deployment failed");
        console.log("Pair Implementation V2.1 deployed at: %s", address(deployed.pairImplV2_1));

        // Deploy V2.2 Factory and Pair Implementation
        console.log("Deploying Factory V2.2...");
        deployed.factoryV2_2 = new LBFactory(deployer, deployer, FLASHLOAN_FEE);
        require(address(deployed.factoryV2_2) != address(0), "Factory V2.2 deployment failed");
        console.log("Factory V2.2 deployed at: %s", address(deployed.factoryV2_2));

        console.log("Deploying Pair Implementation V2.2...");
        deployed.pairImplV2_2 = new LBPair(deployed.factoryV2_2);
        require(address(deployed.pairImplV2_2) != address(0), "Pair Implementation V2.2 deployment failed");
        console.log("Pair Implementation V2.2 deployed at: %s", address(deployed.pairImplV2_2));

        // Deploy Routers
        console.log("Deploying Router V2.1...");
        deployed.routerV2_1 = new LBRouter(
            deployed.factoryV2_1,
            IJoeFactory(address(0)),
            ILBLegacyFactory(address(0)),
            ILBLegacyRouter(address(0)),
            ILBFactory(address(0)),
            IWNATIVE(deployment.w_native)
        );
        require(address(deployed.routerV2_1) != address(0), "Router V2.1 deployment failed");
        console.log("Router V2.1 deployed at: %s", address(deployed.routerV2_1));

        console.log("Deploying Router V2.2...");
        deployed.routerV2_2 = new LBRouter(
            deployed.factoryV2_2,
            IJoeFactory(address(0)),
            ILBLegacyFactory(address(0)),
            ILBLegacyRouter(address(0)),
            ILBFactory(address(deployed.factoryV2_1)),
            IWNATIVE(deployment.w_native)
        );
        require(address(deployed.routerV2_2) != address(0), "Router V2.2 deployment failed");
        console.log("Router V2.2 deployed at: %s", address(deployed.routerV2_2));

        // Deploy Quoter
        console.log("Deploying Quoter...");
        deployed.quoter = new LBQuoter(
            address(0), // factoryV1
            address(0), // factoryV2
            address(deployed.factoryV2_1),
            address(deployed.factoryV2_2),
            address(0), // routerV2
            address(deployed.routerV2_1),
            address(deployed.routerV2_2)
        );
        require(address(deployed.quoter) != address(0), "Quoter deployment failed");
        console.log("Quoter deployed at: %s", address(deployed.quoter));

        vm.stopBroadcast();
        console.log("--- All Contracts Deployed Successfully ---");
    }

    function _configureContracts(DeployedContracts memory deployed, Deployment memory deployment) private {
        console.log("\n--- Configuring Contracts ---");
        
        vm.startBroadcast();

        // Set pair implementations
        console.log("Setting pair implementations...");
        deployed.factoryV2_1.setLBPairImplementation(address(deployed.pairImplV2_1));
        deployed.factoryV2_2.setLBPairImplementation(address(deployed.pairImplV2_2));

        // Add quote assets
        console.log("Adding quote assets...");
        deployed.factoryV2_1.addQuoteAsset(IERC20(deployment.w_native));
        deployed.factoryV2_2.addQuoteAsset(IERC20(deployment.w_native));

        // Configure presets for both factories
        console.log("Configuring presets...");
        _configurePresets(deployed.factoryV2_1);
        _configurePresets(deployed.factoryV2_2);

        vm.stopBroadcast();
        console.log("--- Configuration Complete ---");
    }

    function _configurePresets(LBFactory factory) private {
        uint256[] memory presetList = BipsConfig.getPresetList();
        console.log("Configuring %s presets for factory %s", presetList.length, address(factory));
        
        for (uint256 j = 0; j < presetList.length; j++) {
            BipsConfig.FactoryPreset memory preset = BipsConfig.getPreset(presetList[j]);
            factory.setPreset(
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
    }

    function _transferOwnership(DeployedContracts memory deployed, address multisig) private {
        console.log("\n--- Transferring Ownership ---");
        vm.startBroadcast();

        console.log("Transferring ownership to multisig: %s", multisig);
        deployed.factoryV2_1.transferOwnership(multisig);
        deployed.factoryV2_2.transferOwnership(multisig);
        console.log("Ownership transferred successfully");

        vm.stopBroadcast();
    }

    function _verifyDeployments(DeployedContracts memory deployed, Deployment memory deployment) private view {
        console.log("\n--- Verifying Deployments ---");
        
        // Verify contract addresses
        require(address(deployed.factoryV2_1) != address(0), "Factory V2.1 deployment failed");
        require(address(deployed.factoryV2_2) != address(0), "Factory V2.2 deployment failed");
        require(address(deployed.routerV2_1) != address(0), "Router V2.1 deployment failed");
        require(address(deployed.routerV2_2) != address(0), "Router V2.2 deployment failed");
        require(address(deployed.quoter) != address(0), "Quoter deployment failed");
        
        // Verify ownership
        require(deployed.factoryV2_1.owner() == deployment.multisig, "Factory V2.1 ownership not transferred");
        require(deployed.factoryV2_2.owner() == deployment.multisig, "Factory V2.2 ownership not transferred");
        
        // Verify implementations
        require(
            address(deployed.factoryV2_1.getLBPairImplementation()) == address(deployed.pairImplV2_1),
            "Factory V2.1 implementation not set"
        );
        require(
            address(deployed.factoryV2_2.getLBPairImplementation()) == address(deployed.pairImplV2_2),
            "Factory V2.2 implementation not set"
        );
        
        // Verify quote assets
        require(deployed.factoryV2_1.getNumberOfQuoteAssets() > 0, "No quote assets in V2.1");
        require(deployed.factoryV2_2.getNumberOfQuoteAssets() > 0, "No quote assets in V2.2");
        
        console.log("All verifications passed!");
    }

    function _printDeploymentSummary(
        string memory chainName, 
        DeployedContracts memory deployed, 
        Deployment memory deployment
    ) private view {
        console.log("\n");
        console.log("===== DEPLOYMENT SUMMARY =====");
        console.log("Chain: %s", chainName);
        console.log("Chain ID: %s", vm.toString(block.chainid));
        console.log("Block Number: %s", vm.toString(block.number));
        console.log("");
        console.log("Core Contracts:");
        console.log("  Factory V2.1: %s", address(deployed.factoryV2_1));
        console.log("  Factory V2.2: %s", address(deployed.factoryV2_2));
        console.log("  Router V2.1: %s", address(deployed.routerV2_1));
        console.log("  Router V2.2: %s", address(deployed.routerV2_2));
        console.log("  Quoter: %s", address(deployed.quoter));
        console.log("");
        console.log("Implementation Contracts:");
        console.log("  Pair V2.1: %s", address(deployed.pairImplV2_1));
        console.log("  Pair V2.2: %s", address(deployed.pairImplV2_2));
        console.log("");
        console.log("Configuration:");
        console.log("  Owner: %s", deployment.multisig);
        console.log("  w_native: %s", deployment.w_native);
        console.log("  Flash Loan Fee: %s", FLASHLOAN_FEE);
        console.log("");
        console.log("Presets Configured: %s", BipsConfig.getPresetList().length);
        console.log("===============================");
        console.log("");
    }

    function _setupBSCTestnet() private {
        // Use environment variable for RPC URL if available, fallback to default
        string memory rpcUrl = vm.envOr("BSC_TESTNET_RPC_URL", string("https://bsc-testnet.infura.io/v3/402b910bd7e24d2a866ac48ab3741e75"));

        StdChains.setChain(
            "bnb_smart_chain_testnet",
            StdChains.ChainData({
                name: "BNB Smart Chain Testnet",
                chainId: 97,
                rpcUrl: rpcUrl
            })
        );
    }
}