// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./PigiVestEther.sol";
import "./PigiVestERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract PigiVestFactory {
    address public factoryDeployer;
    
    struct SavingsAccount {
        address accountAddress;
        bool isERC20;
        address tokenAddress; // address(0) for Ether
        uint256 unlockTime;
        uint256 balance;
    }
    
    mapping(address => SavingsAccount) accounts;
    
    address[] allAccounts;
    
    mapping(address => address[]) userAccounts;
    
    event PiggyBankCreated(
        address indexed owner,
        address indexed contractAddress,
        bool isERC20,
        address tokenAddress,
        uint256 unlockTime
    );

    constructor() {
        factoryDeployer = msg.sender;
    }
    
   
    function createEtherSavings(uint256 _unlockTime) external {
        // Add current timestamp to the unlock time
        uint256 unlockTimestamp = block.timestamp + _unlockTime;
        
        // Deploy new PigiVestEther contract
        PigiVestEther newAccount = new PigiVestEther(
            msg.sender,
            unlockTimestamp,
            factoryDeployer
        );
        
        address accountAddress = address(newAccount);
        
        // Store account info
        accounts[accountAddress] = SavingsAccount({
            accountAddress: accountAddress,
            isERC20: false,
            tokenAddress: address(0),
            unlockTime: unlockTimestamp,
            balance: 0
        });
        
        // Track user's accounts
        userAccounts[msg.sender].push(accountAddress);
        allAccounts.push(accountAddress);
        
        emit PiggyBankCreated(
            msg.sender,
            accountAddress,
            false,
            address(0),
            unlockTimestamp
        );
    }
    
    function createERC20Savings(uint256 _unlockTime, address _tokenAddress) external {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        
        // Add current timestamp to the unlock time
        uint256 unlockTimestamp = block.timestamp + _unlockTime;
        
        // Deploy new PigiVestERC20 contract
        PigiVestERC20 newAccount = new PigiVestERC20(
            msg.sender,
            unlockTimestamp,
            _tokenAddress,
            factoryDeployer
        );
        
        address accountAddress = address(newAccount);
        
        // Store account info
        accounts[accountAddress] = SavingsAccount({
            accountAddress: accountAddress,
            isERC20: true,
            tokenAddress: _tokenAddress,
            unlockTime: unlockTimestamp,
            balance: 0
        });
        
        // Track user's accounts
        userAccounts[msg.sender].push(accountAddress);
        allAccounts.push(accountAddress);
        
        emit PiggyBankCreated(
            msg.sender,
            accountAddress,
            true,
            _tokenAddress,
            unlockTimestamp
        );
    }
    
    function getUserAccountAddresses(address _user) external view returns (address[] memory) {
        return userAccounts[_user];
    }

    function getAccountDetails(address _account) external view returns (SavingsAccount memory) {
        return accounts[_account];
    }
    
    function getTotalAccounts() external view returns (uint256) {
        return allAccounts.length;
    }
    
    function getContractBalance(address _contract) external view returns (uint256) {
        return _contract.balance;
    }
    
    function getTokenBalance(address _contract, address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(_contract);
    }
    
    function getUserAccounts(address _user) external view returns (SavingsAccount[] memory) {
        address[] memory userAccountAddresses = userAccounts[_user];
        SavingsAccount[] memory userAccountDetails = new SavingsAccount[](userAccountAddresses.length);
        
        for (uint i = 0; i < userAccountAddresses.length; i++) {
            userAccountDetails[i] = accounts[userAccountAddresses[i]];
        }
        
        return userAccountDetails;
    }
}