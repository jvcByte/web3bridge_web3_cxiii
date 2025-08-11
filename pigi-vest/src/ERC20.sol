// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract PigiVestToken is ERC20, Ownable {
    constructor() ERC20("PIGI-VEST-TOKEN", "PIGI") Ownable(msg.sender) {}
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}