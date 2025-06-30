// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IWBNB {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract WrapBNBScript is Script {
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        IWBNB wbnb = IWBNB(WBNB);
        
        // Wrap 0.2 BNB to get WBNB
        uint256 amountToWrap = 0.2 ether;
        console.log("Wrapping BNB to WBNB...");
        console.log("Amount to wrap:", amountToWrap);
        console.log("Current BNB balance:", address(msg.sender).balance);
        
        // Deposit BNB to get WBNB
        wbnb.deposit{value: amountToWrap}();
        
        uint256 wbnbBalance = wbnb.balanceOf(msg.sender);
        console.log("WBNB balance after wrapping:", wbnbBalance);
        
        vm.stopBroadcast();
    }
}