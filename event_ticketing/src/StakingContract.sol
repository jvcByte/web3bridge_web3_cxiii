// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./errors/EventErrors.sol";

contract StakingContract is ERC721 {

    struct Stake {
        address staker;
        uint256 stakeAmount;
    }
    mapping(address => Stake) public stakes;

    constructor() ERC721("StakingContract", "STK") {}

    function stake() public payable {
        if (msg.value == 0) {
            revert INVALID_AMOUNT();
        }
        
        // Check if msg.value is a whole number (multiple of 1 ether)
        if (msg.value % 1 ether != 0) {
            revert INVALID_AMOUNT();
        }
        
        stakes[msg.sender] = Stake({
            staker: msg.sender,
            stakeAmount: msg.value
        });

        _mint(msg.sender, msg.value);
    }
}
