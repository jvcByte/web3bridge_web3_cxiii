// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./events/PigiVestEvents.sol";
import "./errors/PigiVestErrors.sol";

contract PigiVestEther {
    address public owner;    
    uint256 public unlockTime;
    uint256 public etherBalance;
    address public factoryDeployer;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _owner,
        uint256 _unlockTime,
        address _factoryDeployer
    ) {
        owner = _owner;
        unlockTime = _unlockTime;
        factoryDeployer = _factoryDeployer;
    }

    function DepositEther() public payable {
        etherBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawBeforeUnlockTime() public onlyOwner {
        require(block.timestamp < unlockTime, UseRegularWithdraw());
        
        uint256 _balance = address(this).balance;
        require(_balance > 0, NoBalance());

        (uint256 _amountToSend, uint256 _fee) = remove3PercentFee(_balance);
        
        if (_fee > 0) {
            payable(factoryDeployer).transfer(_fee);
        }
        
        payable(owner).transfer(_amountToSend);
        
        etherBalance = 0;
        
        emit Withdraw(owner, _amountToSend);
        emit Credit3PercentWithdrawal(factoryDeployer, _fee);
    }

    function remove3PercentFee(uint256 _amount) internal pure returns (uint256 _amountToSend, uint256 _fee) {
        require(_amount > 0, InvalidAmount(_amount));

        _fee = (_amount * 3) / 100;
        _amountToSend = _amount - _fee;
        return (_amountToSend, _fee);
    }   

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawETH() public onlyOwner payable {
        require(block.timestamp >= unlockTime, WithdrawalBeforeUnlockTime());
        uint256 _balance = getETHBalance();
        require(_balance > 0, NoBalance());
        payable(owner).transfer(_balance);
        etherBalance = 0;
        emit Withdraw(owner, _balance);
    }

    receive() external payable {
        if (msg.value > 0) {
            etherBalance += msg.value;
            emit Deposit(msg.sender, msg.value);
        }
    }

    fallback() external payable {
        if (msg.value > 0) {
            etherBalance += msg.value;
            emit Deposit(msg.sender, msg.value);
        }
        emit FunctionNotFound(msg.sender, msg.value);
    }
    
}

