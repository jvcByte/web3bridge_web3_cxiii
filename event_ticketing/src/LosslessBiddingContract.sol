// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LosslessBiddingContract
 * @dev A lossless auction contract where outbid participants receive their bid + 10% bonus
 */
contract LosslessBiddingContract is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable biddingToken;
    
    struct Auction {
        uint256 auctionId;
        string itemDescription;
        uint256 startTime;
        uint256 endTime;
        uint256 minBidIncrement;
        address highestBidder;
        uint256 highestBid;
        bool ended;
        bool itemClaimed;
        mapping(address => uint256) totalBidsPlaced;
        mapping(address => uint256) totalBonusesEarned;
    }
    
    mapping(uint256 => Auction) auctions;
    uint256 public auctionCounter;
    uint256 public constant BONUS_PERCENTAGE = 10; // 10%
    uint256 public constant PERCENTAGE_BASE = 100;
    
    event AuctionCreated(
        uint256 indexed auctionId,
        string itemDescription,
        uint256 startTime,
        uint256 endTime,
        uint256 minBidIncrement
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        address indexed previousBidder,
        uint256 previousBid,
        uint256 bonusPaid
    );
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid
    );
    
    event ItemClaimed(
        uint256 indexed auctionId,
        address indexed winner
    );
    
    error AuctionNotStarted();
    error AuctionHasEnded();
    error BidTooLow();
    error SelfBid();
    error AuctionNotEnded();
    error AuctionAlreadyEnded();
    error ItemAlreadyClaimed();
    error NotWinner();
    error InvalidAuction();
    error InvalidTimeRange();
    error InvalidMinBidIncrement();
    
    constructor(address _biddingToken) Ownable(msg.sender) {
        if (_biddingToken == address(0)) revert InvalidAuction();
        biddingToken = IERC20(_biddingToken);
    }
    
    /**
     * @dev Create a new auction
     * @param itemDescription Description of the item being auctioned
     * @param startTime When the auction starts (timestamp)
     * @param duration How long the auction runs (in seconds)
     * @param minBidIncrement Minimum increment between bids
     */
    function createAuction(
        string calldata itemDescription,
        uint256 startTime,
        uint256 duration,
        uint256 minBidIncrement
    ) external onlyOwner returns (uint256) {
        if (startTime < block.timestamp) revert InvalidTimeRange();
        if (duration == 0) revert InvalidTimeRange();
        if (minBidIncrement == 0) revert InvalidMinBidIncrement();
        
        uint256 auctionId = ++auctionCounter;
        uint256 endTime = startTime + duration;
        
        Auction storage auction = auctions[auctionId];
        auction.auctionId = auctionId;
        auction.itemDescription = itemDescription;
        auction.startTime = startTime;
        auction.endTime = endTime;
        auction.minBidIncrement = minBidIncrement;
        
        emit AuctionCreated(auctionId, itemDescription, startTime, endTime, minBidIncrement);
        return auctionId;
    }
    
    /**
     * @dev Place a bid on an auction
     * @param auctionId The auction to bid on
     * @param bidAmount Amount of tokens to bid
     */
    function placeBid(uint256 auctionId, uint256 bidAmount) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        
        if (auction.startTime == 0) revert InvalidAuction();
        if (block.timestamp < auction.startTime) revert AuctionNotStarted();
        if (block.timestamp >= auction.endTime || auction.ended) revert AuctionHasEnded();
        if (msg.sender == auction.highestBidder) revert SelfBid();
        
        uint256 minimumBid = auction.highestBid == 0 
            ? auction.minBidIncrement 
            : auction.highestBid + auction.minBidIncrement;
        
        if (bidAmount < minimumBid) revert BidTooLow();
        
        // Transfer tokens from bidder
        biddingToken.safeTransferFrom(msg.sender, address(this), bidAmount);
        
        address previousBidder = auction.highestBidder;
        uint256 previousBid = auction.highestBid;
        uint256 bonusPaid = 0;
        
        // If there's a previous bidder, pay them back with bonus
        if (previousBidder != address(0) && previousBid > 0) {
            bonusPaid = (previousBid * BONUS_PERCENTAGE) / PERCENTAGE_BASE;
            uint256 totalRefund = previousBid + bonusPaid;
            
            // Update tracking
            auction.totalBonusesEarned[previousBidder] += bonusPaid;
            
            // Transfer refund + bonus to previous bidder
            biddingToken.safeTransfer(previousBidder, totalRefund);
        }
        
        // Update auction state
        auction.highestBidder = msg.sender;
        auction.highestBid = bidAmount;
        auction.totalBidsPlaced[msg.sender] += bidAmount;
        
        emit BidPlaced(auctionId, msg.sender, bidAmount, previousBidder, previousBid, bonusPaid);
    }
    
    /**
     * @dev End an auction manually (can only be called after end time)
     * @param auctionId The auction to end
     */
    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        
        if (auction.startTime == 0) revert InvalidAuction();
        if (block.timestamp < auction.endTime) revert AuctionNotEnded();
        if (auction.ended) revert AuctionAlreadyEnded();
        
        auction.ended = true;
        
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }
    
    /**
     * @dev Claim the auction item (winner only, after auction ends)
     * @param auctionId The auction to claim from
     */
    function claimItem(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        
        if (auction.startTime == 0) revert InvalidAuction();
        if (block.timestamp < auction.endTime && !auction.ended) revert AuctionNotEnded();
        if (auction.itemClaimed) revert ItemAlreadyClaimed();
        if (msg.sender != auction.highestBidder) revert NotWinner();
        
        if (!auction.ended) {
            auction.ended = true;
            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
        }
        
        auction.itemClaimed = true;
        
        emit ItemClaimed(auctionId, msg.sender);
    }
    
    /**
     * @dev Emergency withdrawal function for contract owner
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        biddingToken.safeTransfer(owner(), amount);
    }
    
    // View functions
    
    function getAuctionInfo(uint256 auctionId) external view returns (
        string memory itemDescription,
        uint256 startTime,
        uint256 endTime,
        uint256 minBidIncrement,
        address highestBidder,
        uint256 highestBid,
        bool ended,
        bool itemClaimed
    ) {
        Auction storage auction = auctions[auctionId];
        return (
            auction.itemDescription,
            auction.startTime,
            auction.endTime,
            auction.minBidIncrement,
            auction.highestBidder,
            auction.highestBid,
            auction.ended,
            auction.itemClaimed
        );
    }
    
    function getUserStats(uint256 auctionId, address user) external view returns (
        uint256 totalBidsPlaced,
        uint256 totalBonusesEarned
    ) {
        Auction storage auction = auctions[auctionId];
        return (
            auction.totalBidsPlaced[user],
            auction.totalBonusesEarned[user]
        );
    }
    
    function isAuctionActive(uint256 auctionId) external view returns (bool) {
        Auction storage auction = auctions[auctionId];
        return auction.startTime != 0 && 
               block.timestamp >= auction.startTime && 
               block.timestamp < auction.endTime && 
               !auction.ended;
    }
    
    function getContractBalance() external view returns (uint256) {
        return biddingToken.balanceOf(address(this));
    }

    // Add this function to your contract
function getAuction(uint256 auctionId) external view returns (
    uint256 id,
    string memory itemDescription,
    uint256 startTime,
    uint256 endTime,
    uint256 minBidIncrement,
    address highestBidder,
    uint256 highestBid,
    bool ended,
    bool itemClaimed,
    uint256 totalBidsPlacedByCaller,
    uint256 totalBonusesEarnedByCaller
) {
    Auction storage auction = auctions[auctionId];
    return (
        auction.auctionId,
        auction.itemDescription,
        auction.startTime,
        auction.endTime,
        auction.minBidIncrement,
        auction.highestBidder,
        auction.highestBid,
        auction.ended,
        auction.itemClaimed,
        auction.totalBidsPlaced[msg.sender],
        auction.totalBonusesEarned[msg.sender]
    );
}
}