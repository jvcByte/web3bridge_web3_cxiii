// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PigiVest {
    uint public unlockTime;
    address payable public owner;

    event Deposit(uint amount, uint when);
    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send some ether");
        require(
            block.timestamp < unlockTime,
            "Cannot deposit after unlock time"
        );
        emit Deposit(msg.value, block.timestamp);
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");
        emit Withdrawal(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }

    function adjustUnlockTime(uint newUnlockTime) public {
        require(msg.sender == owner, "You aren't the owner");
        require(
            newUnlockTime > block.timestamp,
            "New unlock time must be in the future"
        );
        require(
            newUnlockTime > unlockTime,
            "New unlock time must be later than current"
        );
        unlockTime = newUnlockTime;
    }
}
