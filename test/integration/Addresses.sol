// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library BscAddresses {
    // BSC Testnet addresses
    address internal constant V2_FACTORY_OWNER = 0xE0A051f87bb78f38172F633449121475a193fC1A; // 实际BSC V2工厂owner
    address internal constant JOE_V1_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17; // PancakeSwap V2 Factory
    address internal constant JOE_V1_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // PancakeSwap V2 Router
    address internal constant JOE_V2_FACTORY = 0x858E3312ed3A876947EA49d572A7C42DE08af7EE; // PancakeSwap V3 Factory
    address internal constant JOE_V2_ROUTER = 0xB5bea8A26d587Cf665f2D7d0eb7c2a45964c0120; // PancakeSwap V3 Router
    address internal constant JOE_V2_1_FACTORY = 0x0000000000000000000000000000000000000000; // 自己的V2.1工厂地址
    address internal constant JOE_V2_1_ROUTER = 0x0000000000000000000000000000000000000000; // 自己的V2.1路由地址
    address internal constant WNATIVE = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB (BSC Testnet)
    address internal constant USDC = 0x64544969ed7EBf5f083679233325356EbE738930; // USDC (BSC Testnet)
    address internal constant USDT = 0x7EF95A0fEe0a8eB89e5e2e5c0bA3Ef1ba5E2e5e2; // USDT (BSC Testnet)
    address internal constant WETH = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca; // WETH (BSC Testnet)
    address internal constant BNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB (BSC Testnet)
}
