// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/ILBRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapScript is Script {
    address constant ROUTER = 0xe98efCE22A8Ec0dd5dDF6C1A81B6ADD740176E98;
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ILBRouter router = ILBRouter(ROUTER);
        
        // Test swap: 0.01 WBNB for USDT
        uint256 amountIn = 0.01 ether;
        
        console.log("Current WBNB balance:", IERC20(WBNB).balanceOf(msg.sender));
        console.log("Current USDT balance:", IERC20(USDT).balanceOf(msg.sender));
        
        // Approve WBNB
        IERC20(WBNB).approve(ROUTER, amountIn);
        
        // Set up swap path
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(WBNB);
        tokenPath[1] = IERC20(USDT);
        
        uint256[] memory pairBinSteps = new uint256[](1);
        pairBinSteps[0] = 25;
        
        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_2;
        
        ILBRouter.Path memory path = ILBRouter.Path({
            pairBinSteps: pairBinSteps,
            versions: versions,
            tokenPath: tokenPath
        });
        
        console.log("Swapping 0.01 WBNB for USDT...");
        console.log("Amount in:", amountIn);
        
        uint256 amountOutMin = 0; // Set appropriate slippage for testing
        
        router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 3600
        );
        
        console.log("Swap completed!");
        console.log("New WBNB balance:", IERC20(WBNB).balanceOf(msg.sender));
        console.log("New USDT balance:", IERC20(USDT).balanceOf(msg.sender));
        
        vm.stopBroadcast();
    }
}