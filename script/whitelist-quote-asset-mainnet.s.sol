// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/ILBFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WhitelistQuoteAssetScript is Script {
    // ✅ BNB Mainnet 上的 ILBFactory 地址
    address constant FACTORY = 0x55268e26DA30fEAc50B26511ba70C5Cac2Af43B8;

    // ✅ BNB Mainnet 上的稳定币地址
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ILBFactory factory = ILBFactory(FACTORY);

        console.log("Adding USDT to quote asset whitelist...");
        console.log("USDT address:", USDT);
        factory.addQuoteAsset(IERC20(USDT));
        console.log("USDT successfully added to whitelist");

        console.log("Adding USDC to quote asset whitelist...");
        console.log("USDC address:", USDC);
        factory.addQuoteAsset(IERC20(USDC));
        console.log("USDC successfully added to whitelist");

        vm.stopBroadcast();
    }
}
