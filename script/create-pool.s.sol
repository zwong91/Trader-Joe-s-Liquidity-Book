// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/ILBFactory.sol";
import "../src/interfaces/ILBRouter.sol";
import "../src/interfaces/ILBPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolScript is Script {
    // BSC Testnet addresses from deployments.json
    address constant FACTORY = 0x7D73A6eFB91C89502331b2137c2803408838218b;
    address constant ROUTER = 0xe98efCE22A8Ec0dd5dDF6C1A81B6ADD740176E98;
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    
    // Token addresses on BSC Testnet
    address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd; // BSC Testnet USDT
    address constant USDC = 0x64544969ed7EBf5f083679233325356EbE738930; // BSC Testnet USDC
    
    // Constants for bin ID calculation
    uint24 internal constant ID_ONE = 2 ** 23; // = 8388608, represents 1:1 price ratio
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ILBFactory factory = ILBFactory(FACTORY);
        ILBRouter router = ILBRouter(ROUTER);
        console.log("=== Creating Three LB Pairs ===");
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));
        console.log("");
        
        // First, add USDC to whitelist if needed
        try factory.addQuoteAsset(IERC20(USDC)) {
            console.log("USDC added to whitelist successfully");
        } catch {
            console.log("USDC already whitelisted or not authorized");
        }
        
        // 1. Create BNB/USDT Pair
        console.log("1. Creating BNB/USDT Pair...");
        ILBPair pairBNBUSDT = createPair(factory, WBNB, USDT, "BNB/USDT", 1, ID_ONE);
        
        // 2. Create BNB/USDC Pair
        console.log("2. Creating BNB/USDC Pair...");
        ILBPair pairBNBUSDC = createPair(factory, WBNB, USDC, "BNB/USDC", 1, ID_ONE);
        
        // 3. Create USDC/USDT Pair (stable pair with smaller bin step)
        console.log("3. Creating USDC/USDT Pair...");
        ILBPair pairUSDCUSDT = createPair(factory, USDC, USDT, "USDC/USDT", 1, ID_ONE); // 0.01% bin step for stablecoins
        
        console.log("=== Summary ===");
        console.log("BNB/USDT Pair:", address(pairBNBUSDT));
        console.log("BNB/USDC Pair:", address(pairBNBUSDC));
        console.log("USDC/USDT Pair:", address(pairUSDCUSDT));
        
        vm.stopBroadcast();
    }
    
    function createPair(
        ILBFactory factory,
        address tokenA,
        address tokenB,
        string memory pairName,
        uint16 binStep,
        uint24 activeId
    ) internal returns (ILBPair pair) {
        console.log("Creating", pairName, "pair...");
        console.log("Token A:", tokenA, getTokenSymbol(tokenA));
        console.log("Token B:", tokenB, getTokenSymbol(tokenB));
        
        // Check if pair already exists
        address existingPair = address(factory.getLBPairInformation(
            IERC20(tokenA),
            IERC20(tokenB),
            binStep
        ).LBPair);
        
        if (existingPair != address(0)) {
            console.log("Pair already exists at:", existingPair);
            console.log("");
            return ILBPair(existingPair);
        }
        
        try factory.createLBPair(
            IERC20(tokenA),
            IERC20(tokenB),
            activeId,
            binStep
        ) returns (ILBPair newPair) {
            console.log(pairName, "pair created at:", address(newPair));
            console.log("");
            return newPair;
        } catch Error(string memory reason) {
            console.log("Failed to create", pairName, "pair:", reason);
            console.log("");
            revert(string(abi.encodePacked("Failed to create ", pairName, " pair: ", reason)));
        }
    }
    
    // Helper function to get token symbol (for better logging)
    function getTokenSymbol(address token) internal pure returns (string memory) {
        if (token == WBNB) return "(WBNB)";
        if (token == USDT) return "(USDT)";
        if (token == USDC) return "(USDC)";
        return "(UNKNOWN)";
    }
}