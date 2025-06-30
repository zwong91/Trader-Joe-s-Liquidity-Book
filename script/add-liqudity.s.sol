// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/ILBRouter.sol";
import "../src/interfaces/ILBPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddLiquidityScript is Script {
    address constant ROUTER = 0xe98efCE22A8Ec0dd5dDF6C1A81B6ADD740176E98;
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    address constant PAIR = 0xa871c952B96ad832ef4B12F1b96B5244a4106090;
    
    uint24 internal constant ID_ONE = 2 ** 23; // 8388608
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ILBRouter router = ILBRouter(ROUTER);
        
        // Amount to add (adjust based on your token balances)
        uint256 amountWBNB = 0.1 ether; // 0.1 WBNB
        uint256 amountUSDT = 30 * 1e18;  // 30 USDT (assuming 1 WBNB = 300 USDT)
        
        // Approve tokens
        IERC20(WBNB).approve(ROUTER, amountWBNB);
        IERC20(USDT).approve(ROUTER, amountUSDT);
        
        // Setup distribution arrays (add liquidity to 11 bins around center)
        int256[] memory deltaIds = new int256[](11);
        uint256[] memory distributionX = new uint256[](11);
        uint256[] memory distributionY = new uint256[](11);
        
        for (uint256 i = 0; i < 11; i++) {
            deltaIds[i] = int256(i) - 5; // [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
            distributionX[i] = 90909090909090909; // ~9.09% each (total ≈ 100%)
            distributionY[i] = 90909090909090909;
        }
        
        ILBRouter.LiquidityParameters memory liquidityParameters = ILBRouter.LiquidityParameters({
            tokenX: IERC20(WBNB),
            tokenY: IERC20(USDT),
            binStep: 25,
            amountX: amountWBNB,
            amountY: amountUSDT,
            amountXMin: (amountWBNB * 95) / 100, // 5% slippage
            amountYMin: (amountUSDT * 95) / 100,
            activeIdDesired: ID_ONE,
            idSlippage: 5,
            deltaIds: deltaIds,
            distributionX: distributionX,
            distributionY: distributionY,
            to: msg.sender,
            refundTo: msg.sender,
            deadline: block.timestamp + 3600
        });
        
        console.log("Adding liquidity to WBNB/USDT pair...");
        console.log("WBNB amount:", amountWBNB);
        console.log("USDT amount:", amountUSDT);
        console.log("Pair address:", PAIR);
        
        router.addLiquidity(liquidityParameters);
        
        console.log("Liquidity added successfully!");
        
        vm.stopBroadcast();
    }
}