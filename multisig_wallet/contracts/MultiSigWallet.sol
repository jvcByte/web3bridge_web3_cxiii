// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    // Custom errors
    error NotOwner();
    error InvalidOwner();
    error InvalidRequiredConfirmations();
    error TransactionNotExists();
    error TransactionAlreadyConfirmed();
    error TransactionNotConfirmed();
    error TransactionAlreadyExecuted();
    error InsufficientConfirmations();
    error TransactionFailed();
    error ZeroAddress();
    error DuplicateOwner();

    // Events
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event TransactionRevoked(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId);
    event Deposit(address indexed sender, uint256 value);

    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredConfirmations;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint256 confirmationCount;
    }

    mapping(uint256 => Transaction) public transactions;

    // Modifiers
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactionCount) revert TransactionNotExists();
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TransactionAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        if (transactions[_txId].isConfirmed[msg.sender]) revert TransactionAlreadyConfirmed();
        _;
    }

    modifier confirmed(uint256 _txId) {
        if (!transactions[_txId].isConfirmed[msg.sender]) revert TransactionNotConfirmed();
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        if (_owners.length == 0) revert InvalidOwner();
        if (_requiredConfirmations == 0 || _requiredConfirmations > _owners.length) {
            revert InvalidRequiredConfirmations();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert ZeroAddress();
            if (isOwner[owner]) revert DuplicateOwner();

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (uint256) {
        uint256 txId = transactionCount;
        
        Transaction storage transaction = transactions[txId];
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        transaction.executed = false;
        transaction.confirmationCount = 0;

        transactionCount++;

        emit TransactionSubmitted(txId, _to, _value);
        return txId;
    }

    function confirmTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmationCount++;

        emit TransactionConfirmed(_txId, msg.sender);
    }

    function revokeConfirmation(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        confirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmationCount--;

        emit TransactionRevoked(_txId, msg.sender);
    }

    function executeTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        
        if (transaction.confirmationCount < requiredConfirmations) {
            revert InsufficientConfirmations();
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) revert TransactionFailed();

        emit TransactionExecuted(_txId);
    }

    // View functions
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function getTransaction(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmationCount
        )
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmationCount
        );
    }

    function isConfirmedBy(uint256 _txId, address _owner)
        external
        view
        txExists(_txId)
        returns (bool)
    {
        return transactions[_txId].isConfirmed[_owner];
    }

    function getConfirmationCount(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (uint256)
    {
        return transactions[_txId].confirmationCount;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}