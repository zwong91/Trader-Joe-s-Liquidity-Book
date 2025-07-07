// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/ILBFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WhitelistQuoteAssetScript is Script {
    address constant FACTORY = 0x7D73A6eFB91C89502331b2137c2803408838218b;
    address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    address constant USDC = 0x64544969ed7EBf5f083679233325356EbE738930;
    address constant BNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB

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

        console.log("Adding BNB (WBNB) to quote asset whitelist...");
        console.log("BNB address:", BNB);
        factory.addQuoteAsset(IERC20(BNB));
        console.log("BNB (WBNB) successfully added to whitelist");

        vm.stopBroadcast();
    }
}