// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

event Deposit(address indexed From, uint256 Amount, uint256 Timestamp);
event TransactionSubmitted(address indexed Initiator, uint256 TxId, address To, uint256 Value, bytes Data);
event TransactionConfirmed(address indexed Initiator, uint256 TxId);
event TransactionExecuted(address indexed Initiator, uint256 TxId);
event TransactionConfirmationRevoked(address indexed Initiator, uint256 TxId);


event OwnerAdded(address indexed Initiator, address Owner);
event OwnerRemoved(address indexed Initiator, address Owner);