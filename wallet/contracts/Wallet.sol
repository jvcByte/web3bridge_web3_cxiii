// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract jvcbyteWallet {
    // State variables
    uint256 public balance;
    address public owner;

    constructor() {
        owner = msg.sender; // Set the contract creator as the owner
        balance = 0; // Initialize balance to zero
    }

    // Events to be emmitted
    event Deposit(address from, uint256 amount);
    event Withdrawal(address to, uint256 amount);

    // Functions needed for wallet operations
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit Deposit(msg.sender, msg.value); // Emit a deposit event
        balance += msg.value; // Increase the balance by the deposited amount
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        require(balance > 0, "Insufficient balance to withdraw");
        require(
            address(this).balance >= balance,
            "Contract balance is less than wallet balance"
        );

        emit Withdrawal(owner, balance); // Emit a withdrawal event
        payable(owner).transfer(balance); // Transfer the balance to the owner
        balance = 0; // Reset the balance after withdrawal
    }
}
