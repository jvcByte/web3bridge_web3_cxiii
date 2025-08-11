// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LosslessBiddingContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock ERC20 token that doesn't return bool (like USDT)
contract NonBoolERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string public name = "NonBoolToken";
    string public symbol = "NBT";
    uint8 public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address to, uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        // Note: No return value (like USDT)
    }
    
    function approve(address spender, uint256 amount) external {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        // Note: No return value
    }
    
    function transferFrom(address from, address to, uint256 amount) external {
        require(_balances[from] >= amount, "Insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        // Note: No return value (like USDT)
    }
    
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract LosslessBiddingTest is Test {
    LosslessBiddingContract public auction;
    MockERC20 public token;
    
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    address public david = address(0x4);
    
    uint256 public constant INITIAL_BALANCE = 1000e18;
    uint256 public constant MIN_BID_INCREMENT = 100e18;
    uint256 public constant AUCTION_DURATION = 1 hours;
    
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
    
    function setUp() public {
        token = new MockERC20();
        auction = new LosslessBiddingContract(address(token));
        
        // Mint tokens to test users
        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);
        token.mint(charlie, INITIAL_BALANCE);
        token.mint(david, INITIAL_BALANCE);
        
        // Set up approvals
        vm.prank(alice);
        token.approve(address(auction), type(uint256).max);
        vm.prank(bob);
        token.approve(address(auction), type(uint256).max);
        vm.prank(charlie);
        token.approve(address(auction), type(uint256).max);
        vm.prank(david);
        token.approve(address(auction), type(uint256).max);
    }
    
    function testCreateAuction() public {
        uint256 startTime = block.timestamp + 1;
        
        vm.expectEmit(true, false, false, true);
        emit AuctionCreated(1, "Test Item", startTime, startTime + AUCTION_DURATION, MIN_BID_INCREMENT);
        
        uint256 auctionId = auction.createAuction(
            "Test Item",
            startTime,
            AUCTION_DURATION,
            MIN_BID_INCREMENT
        );
        
        assertEq(auctionId, 1);
        
        (
            string memory description,
            uint256 start,
            uint256 end,
            uint256 minIncrement,
            address highestBidder,
            uint256 highestBid,
            bool ended,
            bool claimed
        ) = auction.getAuctionInfo(auctionId);
        
        assertEq(description, "Test Item");
        assertEq(start, startTime);
        assertEq(end, startTime + AUCTION_DURATION);
        assertEq(minIncrement, MIN_BID_INCREMENT);
        assertEq(highestBidder, address(0));
        assertEq(highestBid, 0);
        assertFalse(ended);
        assertFalse(claimed);
    }
    
    function testCreateAuctionInvalidParams() public {
        // Test invalid start time
        vm.expectRevert();
        auction.createAuction("Test", block.timestamp - 1, AUCTION_DURATION, MIN_BID_INCREMENT);
        
        // Test zero duration
        vm.expectRevert();
        auction.createAuction("Test", block.timestamp + 1, 0, MIN_BID_INCREMENT);
        
        // Test zero min bid increment
        vm.expectRevert();
        auction.createAuction("Test", block.timestamp + 1, AUCTION_DURATION, 0);
    }
    
    function testSingleBid() public {
        uint256 auctionId = createTestAuction();
        uint256 bidAmount = MIN_BID_INCREMENT;
        
        vm.warp(block.timestamp + 2); // Move past start time
        
        vm.expectEmit(true, true, false, true);
        emit BidPlaced(auctionId, alice, bidAmount, address(0), 0, 0);
        
        vm.prank(alice);
        auction.placeBid(auctionId, bidAmount);
        
        (, , , , address highestBidder, uint256 highestBid, ,) = auction.getAuctionInfo(auctionId);
        assertEq(highestBidder, alice);
        assertEq(highestBid, bidAmount);
        
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - bidAmount);
        assertEq(token.balanceOf(address(auction)), bidAmount);
    }
    
    function testMultipleBidsWithBonus() public {
        uint256 auctionId = createTestAuction();
        uint256 aliceBid = MIN_BID_INCREMENT;
        uint256 bobBid = aliceBid + MIN_BID_INCREMENT;
        uint256 charlieBid = bobBid + MIN_BID_INCREMENT;
        
        vm.warp(block.timestamp + 2);
        
        // Alice bids first
        vm.prank(alice);
        auction.placeBid(auctionId, aliceBid);
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 expectedBonus = (aliceBid * 10) / 100;
        
        // Bob outbids Alice
        vm.expectEmit(true, true, true, true);
        emit BidPlaced(auctionId, bob, bobBid, alice, aliceBid, expectedBonus);
        
        vm.prank(bob);
        auction.placeBid(auctionId, bobBid);
        
        // Check Alice received her bid + bonus
        assertEq(token.balanceOf(alice), aliceBalanceBefore + aliceBid + expectedBonus);
        
        // Check Alice's stats
        (uint256 totalBids, uint256 totalBonuses) = auction.getUserStats(auctionId, alice);
        assertEq(totalBids, aliceBid);
        assertEq(totalBonuses, expectedBonus);
        
        // Charlie outbids Bob
        uint256 bobBalanceBefore = token.balanceOf(bob);
        uint256 expectedBobBonus = (bobBid * 10) / 100;
        
        vm.prank(charlie);
        auction.placeBid(auctionId, charlieBid);
        
        // Check Bob received his bid + bonus
        assertEq(token.balanceOf(bob), bobBalanceBefore + bobBid + expectedBobBonus);
        
        (, , , , address highestBidder, uint256 highestBid, ,) = auction.getAuctionInfo(auctionId);
        assertEq(highestBidder, charlie);
        assertEq(highestBid, charlieBid);
    }
    
    function testBidValidation() public {
        uint256 auctionId = createTestAuction();
        
        // Test bidding before auction starts
        vm.expectRevert();
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        vm.warp(block.timestamp + 2);
        
        // Test bid too low
        vm.expectRevert();
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT - 1);
        
        // Place valid bid
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        // Test self bid
        vm.expectRevert();
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT * 2);
        
        // Test bid after auction ends
        vm.warp(block.timestamp + AUCTION_DURATION + 1);
        vm.expectRevert();
        vm.prank(bob);
        auction.placeBid(auctionId, MIN_BID_INCREMENT * 2);
    }
    
    function testAuctionEnd() public {
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        // Try to end before time
        vm.expectRevert();
        auction.endAuction(auctionId);
        
        // Move to after auction end
        vm.warp(block.timestamp + AUCTION_DURATION + 1);
        
        auction.endAuction(auctionId);
        
        (, , , , , , bool ended,) = auction.getAuctionInfo(auctionId);
        assertTrue(ended);
        
        // Try to end again
        vm.expectRevert();
        auction.endAuction(auctionId);
    }
    
    function testClaimItem() public {
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        // Try to claim before auction ends
        vm.expectRevert();
        vm.prank(alice);
        auction.claimItem(auctionId);
        
        vm.warp(block.timestamp + AUCTION_DURATION + 1);
        
        // Try to claim as non-winner
        vm.expectRevert();
        vm.prank(bob);
        auction.claimItem(auctionId);
        
        // Claim as winner
        vm.prank(alice);
        auction.claimItem(auctionId);
        
        (, , , , , , bool ended, bool claimed) = auction.getAuctionInfo(auctionId);
        assertTrue(ended);
        assertTrue(claimed);
        
        // Try to claim again
        vm.expectRevert();
        vm.prank(alice);
        auction.claimItem(auctionId);
    }
    
    function testComplexBiddingScenario() public {
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        // Track initial balances
        uint256 aliceInitial = token.balanceOf(alice);
        uint256 bobInitial = token.balanceOf(bob);
        uint256 charlieInitial = token.balanceOf(charlie);
        
        // Place initial bids
        placeInitialBids(auctionId, aliceInitial, bobInitial, charlieInitial);
        
        // Verify final state and user stats
        verifyFinalState(auctionId, aliceInitial);
    }
    
    function placeInitialBids(uint256 auctionId, uint256 aliceInitial, uint256 bobInitial, uint256 charlieInitial) private {
        // Alice bids 100
        uint256 aliceBid1 = 100e18;
        vm.prank(alice);
        auction.placeBid(auctionId, aliceBid1);
        
        // Bob bids 250 (outbids Alice)
        uint256 bobBid1 = 250e18;
        vm.prank(bob);
        auction.placeBid(auctionId, bobBid1);
        
        // Alice should get 100 + 10 = 110 back
        assertEq(token.balanceOf(alice), aliceInitial - aliceBid1 + aliceBid1 + 10e18);
        
        // Charlie bids 400 (outbids Bob)
        uint256 charlieBid1 = 400e18;
        vm.prank(charlie);
        auction.placeBid(auctionId, charlieBid1);
        
        // Bob should get 250 + 25 = 275 back
        assertEq(token.balanceOf(bob), bobInitial - bobBid1 + bobBid1 + 25e18);
        
        // Alice bids again with 600 (outbids Charlie)
        uint256 aliceBid2 = 600e18;
        vm.prank(alice);
        auction.placeBid(auctionId, aliceBid2);
        
        // Charlie should get 400 + 40 = 440 back
        assertEq(token.balanceOf(charlie), charlieInitial - charlieBid1 + charlieBid1 + 40e18);
    }
    
    function verifyFinalState(uint256 auctionId, uint256 aliceInitial) private view {
        // Check final state
        (, , , , address winner, uint256 winningBid, ,) = auction.getAuctionInfo(auctionId);
        assertEq(winner, alice);
        assertEq(winningBid, 600e18); // aliceBid2
        
        // Check that Alice's final balance is correct
        // Initial - first bid + refund + bonus - second bid
        uint256 expectedAliceBalance = aliceInitial - 100e18 + 100e18 + 10e18 - 600e18;
        assertEq(token.balanceOf(alice), expectedAliceBalance);
        
        // Verify user stats
        (uint256 aliceTotalBids, uint256 aliceTotalBonuses) = auction.getUserStats(auctionId, alice);
        assertEq(aliceTotalBids, 700e18); // aliceBid1 + aliceBid2
        assertEq(aliceTotalBonuses, 10e18);
        
        (uint256 bobTotalBids, uint256 bobTotalBonuses) = auction.getUserStats(auctionId, bob);
        assertEq(bobTotalBids, 250e18); // bobBid1
        assertEq(bobTotalBonuses, 25e18);
        
        (uint256 charlieTotalBids, uint256 charlieTotalBonuses) = auction.getUserStats(auctionId, charlie);
        assertEq(charlieTotalBids, 400e18); // charlieBid1
        assertEq(charlieTotalBonuses, 40e18);
    }
    
    function testEmergencyWithdraw() public {
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        uint256 contractBalance = auction.getContractBalance();
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        auction.emergencyWithdraw(contractBalance);
        
        assertEq(token.balanceOf(owner), ownerBalanceBefore + contractBalance);
        assertEq(auction.getContractBalance(), 0);
    }
    
    function testViewFunctions() public {
        uint256 auctionId = createTestAuction();
        
        // Test isAuctionActive
        assertFalse(auction.isAuctionActive(auctionId)); // Not started yet
        
        vm.warp(block.timestamp + 2);
        assertTrue(auction.isAuctionActive(auctionId)); // Now active
        
        vm.warp(block.timestamp + AUCTION_DURATION + 1);
        assertFalse(auction.isAuctionActive(auctionId)); // Ended
        
        // Test getContractBalance
        vm.warp(block.timestamp - AUCTION_DURATION + 1); // Back to active
        vm.prank(alice);
        auction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        assertEq(auction.getContractBalance(), MIN_BID_INCREMENT);
    }
    
    function testInvalidAuctionOperations() public {
        uint256 invalidAuctionId = 999;
        
        vm.expectRevert();
        vm.prank(alice);
        auction.placeBid(invalidAuctionId, MIN_BID_INCREMENT);
        
        vm.expectRevert();
        auction.endAuction(invalidAuctionId);
        
        vm.expectRevert();
        vm.prank(alice);
        auction.claimItem(invalidAuctionId);
    }
    
    function testBonusCalculationPrecision() public {
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        // Test with amount that doesn't divide evenly by 100
        uint256 oddBid = 133e18; // 10% = 13.3e18
        vm.prank(alice);
        auction.placeBid(auctionId, oddBid);
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 expectedBonus = (oddBid * 10) / 100; // Should be 13.3e18
        
        vm.prank(bob);
        auction.placeBid(auctionId, oddBid + MIN_BID_INCREMENT);
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore + oddBid + expectedBonus);
        
        (,uint256 aliceBonuses) = auction.getUserStats(auctionId, alice);
        assertEq(aliceBonuses, expectedBonus);
    }
    
    // Helper function to create a test auction
    function createTestAuction() internal returns (uint256) {
        return auction.createAuction(
            "Test Item",
            block.timestamp + 1,
            AUCTION_DURATION,
            MIN_BID_INCREMENT
        );
    }
    
    // Fuzz testing
    function testFuzzBiddingAmounts(uint96 bidAmount) public {
        vm.assume(bidAmount >= MIN_BID_INCREMENT && bidAmount <= INITIAL_BALANCE);
        
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        vm.prank(alice);
        auction.placeBid(auctionId, bidAmount);
        
        (, , , , address highestBidder, uint256 highestBid, ,) = auction.getAuctionInfo(auctionId);
        assertEq(highestBidder, alice);
        assertEq(highestBid, bidAmount);
    }
    
    function testFuzzBonusCalculation(uint96 bidAmount) public {
        vm.assume(bidAmount >= MIN_BID_INCREMENT && bidAmount <= INITIAL_BALANCE / 2);
        
        uint256 auctionId = createTestAuction();
        vm.warp(block.timestamp + 2);
        
        vm.prank(alice);
        auction.placeBid(auctionId, bidAmount);
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 expectedBonus = (bidAmount * 10) / 100;
        
        vm.prank(bob);
        auction.placeBid(auctionId, bidAmount + MIN_BID_INCREMENT);
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore + bidAmount + expectedBonus);
    }
    
    function testWithNonBoolERC20Token() public {
        // Deploy non-bool returning ERC20 token (like USDT)
        NonBoolERC20 nonBoolToken = new NonBoolERC20();
        LosslessBiddingContract nonBoolAuction = new LosslessBiddingContract(address(nonBoolToken));
        
        // Mint tokens
        nonBoolToken.mint(alice, INITIAL_BALANCE);
        nonBoolToken.mint(bob, INITIAL_BALANCE);
        
        // Set approvals
        vm.prank(alice);
        nonBoolToken.approve(address(nonBoolAuction), type(uint256).max);
        vm.prank(bob);
        nonBoolToken.approve(address(nonBoolAuction), type(uint256).max);
        
        // Create auction
        uint256 auctionId = nonBoolAuction.createAuction(
            "Test Item",
            block.timestamp + 1,
            AUCTION_DURATION,
            MIN_BID_INCREMENT
        );
        
        vm.warp(block.timestamp + 2);
        
        // Test bidding with non-bool token
        vm.prank(alice);
        nonBoolAuction.placeBid(auctionId, MIN_BID_INCREMENT);
        
        uint256 aliceBalanceBefore = nonBoolToken.balanceOf(alice);
        
        vm.prank(bob);
        nonBoolAuction.placeBid(auctionId, MIN_BID_INCREMENT * 2);
        
        // Verify Alice received refund + bonus
        uint256 expectedBonus = (MIN_BID_INCREMENT * 10) / 100;
        assertEq(nonBoolToken.balanceOf(alice), aliceBalanceBefore + MIN_BID_INCREMENT + expectedBonus);
        
        (, , , , address winner, uint256 winningBid, ,) = nonBoolAuction.getAuctionInfo(auctionId);
        assertEq(winner, bob);
        assertEq(winningBid, MIN_BID_INCREMENT * 2);
    }
}