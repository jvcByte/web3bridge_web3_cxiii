// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);
    event FunctionNotFound(address indexed sender, uint256 amount);
    event Credit3PercentWithdrawal(address indexed receiver, uint256 amount);