// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.28;

// import {Test, console} from "forge-std/Test.sol";
// import {Counter} from "../src/Counter.sol";

// contract CounterFactory is Test {
//     CounterFactory public factory;

//     function setUp() public {
//         factory = new CounterFactory();
//     }

//     function testDeployCounter() public {
//         uint256 counterBeforeDeploy = factory.counterCount();
//         factory.deployCounter();
//         uint256 counterAfterDeploy = factory.counterCount();
//         assert(counterAfterDeploy > counterBeforeDeploy);
//     }
// }