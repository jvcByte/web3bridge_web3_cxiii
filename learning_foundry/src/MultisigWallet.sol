// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./errors/MultisigWalletErrors.sol";
import "./events/MultisigWalletEvents.sol";

contract MultisigWallet {
    uint256 public ownerCount;
    uint256 public requiredConfirmations;
    address[] public owners;
    mapping(address => bool) public isOwner;

    struct Transaction {
        uint256 txId;
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], INVALID_ADDRESS(msg.sender));
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, NON_EXISTING_TX(_txId));
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!isConfirmed[_txId][msg.sender], TX_ALREADY_CONFIRMED(_txId));
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, TX_ALREADY_EXECUTED(_txId));
        _;
    }

    constructor(
        address[] memory _owners,
        uint256 _requiredConfirmations
    ) {
        require(_owners.length > 0, INVALID_OWNER_COUNT(_owners.length));
        require( 
            _requiredConfirmations > 0 &&
            _requiredConfirmations <= _owners.length,
             INVALID_CONFIRMATIONS_COUNT(_requiredConfirmations)
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), INVALID_ADDRESS(_owners[i]));
            owners.push(_owners[i]);
            ownerCount ++;
            isOwner[_owners[i]] = true;
        }
        requiredConfirmations = _requiredConfirmations;
    }
    
    function submitTransaction(address _to, uint256 _value, bytes memory _data)
     public 
     onlyOwner 
    {
        uint256 txId = transactions.length;
        transactions.push(Transaction({
            txId: txId,
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));

        emit TransactionSubmitted({
            TxId:txId,
            Initiator:msg.sender,
            To:_to,
            Value:_value,
            Data:_data
        });
    }

    function confirmTransaction(uint256 _txId)
     public 
     onlyOwner 
     txExists(_txId) 
     notConfirmed(_txId) 
     notExecuted(_txId)
    {
        Transaction storage _tx = transactions[_txId];
        _tx.confirmations++;
        isConfirmed[_txId][msg.sender] = true;

        emit TransactionConfirmed({
            TxId:_txId,
            Initiator:msg.sender
        });
    }

    function executeTransaction(uint256 _txId)
     public 
     onlyOwner 
     txExists(_txId) 
     notExecuted(_txId)
    {
        Transaction storage _tx = transactions[_txId];
        require(_tx.confirmations >= requiredConfirmations, REQUIRED_CONFIRMATIONS_NOT_MET(_txId));
        (bool success, ) = _tx.to.call{value: _tx.value}(_tx.data);

        require(success, TX_EXECUTION_FAILED(_txId));
        _tx.executed = true;
        emit TransactionExecuted({
            TxId:_txId,
            Initiator:msg.sender
        });
    }

    function revokeConfirmation(uint256 _txId)
     public 
     onlyOwner 
     txExists(_txId) 
     notExecuted(_txId)
    {
        Transaction storage _tx = transactions[_txId];
        require(isConfirmed[_txId][msg.sender], TX_NOT_CONFIRMED(_txId));
        _tx.confirmations--;
        isConfirmed[_txId][msg.sender] = false;

        emit TransactionConfirmationRevoked({
            TxId:_txId,
            Initiator:msg.sender
        });
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256 _TxCount) {
        _TxCount = transactions.length;
    }

    function getTransaction(uint256 _txId) 
    public 
    view 
    txExists(_txId)
    returns (
        address _to, 
        uint256 _value, 
        bytes memory _data, 
        bool _executed, 
        uint256 _confirmations ) {
            Transaction memory _tx = transactions[_txId];
        return (
            _tx.to, 
            _tx.value, 
            _tx.data, 
            _tx.executed, 
            _tx.confirmations
        );
    }

    receive() external payable {
        emit Deposit({
            From: msg.sender,
            Amount: msg.value,
            Timestamp: block.timestamp
        });
    }
}