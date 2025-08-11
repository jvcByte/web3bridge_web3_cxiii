// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

error INVALID_CONFIRMATIONS_COUNT(uint256 count);
error INVALID_OWNER_COUNT(uint256 count);
error INVALID_ADDRESS(address addr);
error NON_EXISTING_TX(uint256 txId);
error TX_ALREADY_CONFIRMED(uint256 txId);
error TX_ALREADY_EXECUTED(uint256 txId);
error REQUIRED_CONFIRMATIONS_NOT_MET(uint256 txId);
error TX_EXECUTION_FAILED(uint256 txId);
error TX_NOT_CONFIRMED(uint256 txId);

