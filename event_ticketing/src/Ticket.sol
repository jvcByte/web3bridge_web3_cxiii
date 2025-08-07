// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./errors/EventErrors.sol";

contract Ticket is ERC1155, Ownable {

    string uriPath = "";
    uint256 public ticketCount;
    string public eventTitle;
    string public eventSymbol;
    address public eventOwner;

    constructor(
        string memory _eventTitle,
        string memory _eventSymbol,
        address _owner
    ) ERC1155(uriPath) Ownable(_owner) {
        eventTitle = _eventTitle;
        eventSymbol = _eventSymbol;
        eventOwner = _owner;
    }

    function _mintTicket(address _to, uint256 _amount) external onlyOwner {

        if (_to == address(0)) {
            revert ADDRESS_ZERO();
        }
        if (_amount <= 0) {
            revert INVALID_AMOUNT();
        }
        
        _mint(_to, _amount, _amount, "");

        ticketCount += _amount;
    }
    
}