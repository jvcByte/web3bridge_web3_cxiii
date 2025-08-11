// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

error InsufficientAllowance(address sender, address receiver, uint256 amount);
error UseRegularWithdraw();
error NoBalance();
error InvalidAmount(uint256 amount);
error WithdrawalBeforeUnlockTime();

