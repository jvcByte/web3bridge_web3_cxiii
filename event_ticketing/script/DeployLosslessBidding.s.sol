// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LosslessBiddingContract} from "../src/LosslessBiddingContract.sol";

contract DeployLosslessBidding is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        address tokenAddress = 0x10e4d4120a107422d4292382D09Fc86821fa3f82;
        new LosslessBiddingContract(tokenAddress);
        
        vm.stopBroadcast();
    }
}


// PRIVATE_KEY=0x00c6c1a1536d2e24d230fa7ee46081184b7d72484dc71e732f41ea61cb9cda7b \
// forge script script/DeployLosslessBidding.s.sol:DeployLosslessBidding \
// --rpc-url https://base-sepolia.drpc.org \
// --broadcast \
// --verify \
// --etherscan-api-key VDYBRCPI7S39YEQDXIAFUDMI3TCMQPNDUQ \
// -vvv
