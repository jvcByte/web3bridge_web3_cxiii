// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./events/PigiVestEvents.sol";
import "./errors/PigiVestErrors.sol";

contract PigiVestERC20 {
    using SafeERC20 for IERC20;
    IERC20 public token;
    address public owner;    
    uint256 public unlockTime;
    address public factoryDeployer;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _owner,
        uint256 _unlockTime,
        address _token,
        address _factoryDeployer
    ) {
        owner = _owner;
        unlockTime = _unlockTime;
        token = IERC20(_token);
        factoryDeployer = _factoryDeployer;
    }

    function depositERC20(uint256 _amount) public {
        require(_amount > 0, InvalidAmount(_amount));
        uint256 _allowance = getAllowance(msg.sender);
        require(_allowance >= _amount, InsufficientAllowance(msg.sender, address(this), _amount));
        
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdrawBeforeUnlockTime() public onlyOwner {
        require(block.timestamp < unlockTime, UseRegularWithdraw());
        
        uint256 _balance = getERC20Balance();
        require(_balance > 0, NoBalance());

        (uint256 _amountToSend, uint256 _fee) = remove3PercentFee(_balance);
        
        if (_fee > 0) {
            token.safeTransfer(factoryDeployer, _fee);
        }
        
        token.safeTransfer(owner, _amountToSend);
                
        emit Withdraw(owner, _amountToSend);
        emit Credit3PercentWithdrawal(factoryDeployer, _fee);
    }

    function remove3PercentFee(uint256 _amount) internal pure returns (uint256 _amountToSend, uint256 _fee) {
        require(_amount > 0, InvalidAmount(_amount));

        _fee = (_amount * 3) / 100;
        _amountToSend = _amount - _fee;
        return (_amountToSend, _fee);
    } 


    function getERC20Balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getAllowance(address _user) public view returns (uint256) {
        return token.allowance(_user, address(this));
    }

    function withdrawERC20() public onlyOwner {
        uint256 _balance = getERC20Balance();
        require(_balance > 0, NoBalance());
        token.safeTransfer(owner, _balance);
        emit Withdraw(owner, _balance);
    }
    
}

