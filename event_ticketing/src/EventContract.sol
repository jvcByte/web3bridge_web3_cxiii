// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./errors/EventErrors.sol";
import {Ticket} from "./Ticket.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract EventContract {

    address public EventContractOwner;
    uint256 public balance;

    uint256 public eventCount;

    event EventCreated(
        uint256 indexed eventId,
        string title,
        address organizer
    );

    event TransactionReceived(
        address indexed sender,
        uint256 amount
    );
    event ERC20Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event TicketPurchased(
        uint256 indexed eventId,
        address indexed buyer,
        uint256 amount,
        address paymentToken,
        uint256 totalCost
    );

    enum EventType {
        Free,
        Paid
    }

    enum EventStatus {
        Upcoming,
        Ongoing,
        Completed,
        Cancelled
    }

    struct Event {
        string title;
        string description;
        uint256 startDate;
        uint256 endDate;
        address organizer;
        uint256 ticketPrice;
        string eventBanner;
        EventStatus status;
        EventType eventType;
        uint256 totalTickets;
        address ticketAddress;
    }

    mapping(uint256 => Event) public events;

    modifier onlyOwner() {
        if (msg.sender != EventContractOwner) {
            revert INVALID_OWNER();
        }
        _;
    }

    constructor() {
        EventContractOwner = msg.sender;
    }


    function createEvent(string memory _title, string memory _description, uint256 _startDate, uint256 _endDate, uint256 _ticketPrice, string memory _eventBanner, EventType _eventType, uint256 _totalTickets, EventStatus _status) public returns(uint256) {
        require(msg.sender != address(0), ADDRESS_ZERO());
        require(_startDate < _endDate, INVALID_DATE_RANGE());

        uint256 _event_id = eventCount + 1;

        Ticket newTicket = new Ticket(_title, _title, msg.sender);

        events[_event_id] = Event({
            title: _title,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            organizer: msg.sender,
            ticketPrice: _ticketPrice,
            eventBanner: _eventBanner,
            status: _status,
            eventType: _eventType,
            totalTickets: _totalTickets,
            ticketAddress: address(newTicket)
        });

        eventCount++;
        
        emit EventCreated(_event_id, _title, msg.sender);

        return _event_id;
    }

    function purchaseTicketWithToken(
        uint256 _eventId, 
        uint256 _amount, 
        IERC20 _paymentToken
    ) public {
        if(_amount <= 0) {
            revert INVALID_AMOUNT();
        }
        // Check if the event exists
        if( _eventId > eventCount) {
            revert INVALID_EVENT_ID();
        }
        
        Event storage eventData = events[_eventId];
        uint256 totalCost = eventData.ticketPrice * _amount;
        
        // Transfer tokens from user to this contract
        _paymentToken.transferFrom(msg.sender, address(this), totalCost);
        
        balance += totalCost;

        
        // Mint the NFT tickets
        mintTicket(_eventId, _amount);
        
        // Emit an event for the purchase
        emit TicketPurchased(_eventId, msg.sender, _amount, address(_paymentToken), totalCost);
    }
    
    // Keep the original mint function for owner/other purposes
    function mintTicket(uint256 _eventId, uint256 _amount) internal {
        
        Ticket ticket = Ticket(events[_eventId].ticketAddress);
        ticket._mintTicket(msg.sender, _amount);
    }


    function withdraw(uint256 _amount) public onlyOwner{
        if (_amount > balance) {
            revert INVALID_AMOUNT();
        }
        payable(msg.sender).transfer(_amount);
        balance -= _amount;
    }

    function transferERC20(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        uint256 erc20Balance = _token.balanceOf(address(this));
        
        if (erc20Balance < _amount) {
            revert INVALID_AMOUNT();
        }
        if (_to == address(0)) {
            revert ADDRESS_ZERO();
        }
        _token.transfer(_to, _amount);
        balance -= _amount;
        emit ERC20Transfer(msg.sender, _to, _amount);
    }

    receive() external payable {
        balance += msg.value;
        emit TransactionReceived(msg.sender, msg.value);
    }

    function purchaseTicket(uint256 _eventId) public {
        Event storage eventDetails = events[_eventId];
        require(msg.sender != address(0), ADDRESS_ZERO());
        require(eventDetails.ticketAddress != address(0), EVENT_NOT_FOUND(_eventId));
        require(eventDetails.status == EventStatus.Upcoming || eventDetails.status == EventStatus.Ongoing, INACTIVE_EVENT(_eventId));

        uint256 _balance = IERC20(eventDetails.ticketAddress).balanceOf(msg.sender);
        require(_balance >= eventDetails.ticketPrice, INSUFFICIENT_BALANCE());

        IERC721(eventDetails.ticketAddress).safeMint(msg.sender);
        // IERC20(tokenAddress).safeTransferFrom(msg.sender, eventDetails.organizer, eventDetails.ticketPrice);


    }
}