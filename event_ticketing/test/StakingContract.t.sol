// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.30;

// import {Test, console} from "forge-std/Test.sol";
// import {StakingContract} from "../src/StakingContract.sol";

// contract StakingContractTest is Test {
//     StakingContract public stakingContract;
    
//     // Test addresses
//     address public alice = makeAddr("alice");
//     uint256 public constant STAKE_AMOUNT = 1 ether;
    
//     function setUp() public {
//         // Deploy the staking contract
//         stakingContract = new StakingContract();
        
//         // Fund Alice with some ETH
//         vm.deal(alice, 10 ether);
//     }
    
//     // Test successful staking with 1 ETH
//     function testStakeSuccess() public {
//         // Alice stakes 1 ETH
//         vm.prank(alice);
//         stakingContract.stake{value: STAKE_AMOUNT}();
        
//         // Check the stake was recorded correctly
//         (address staker, uint256 amount) = stakingContract.stakes(alice);
//         assertEq(staker, alice, "Staker address should be Alice");
//         assertEq(amount, STAKE_AMOUNT, "Staked amount should be 1 ETH");
        
//         // Check NFT was minted to Alice
//         assertEq(stakingContract.ownerOf(STAKE_AMOUNT), alice, "Alice should own the NFT");
//     }
    
//     // Test staking zero ETH should revert
//     function testStakeZeroAmount() public {
//         vm.prank(alice);
//         vm.expectRevert(abi.encodeWithSignature("INVALID_AMOUNT()"));
//         stakingContract.stake{value: 0}();
//     }
    
//     // Test staking a non-whole number of ETH should revert
//     function testStakeNonWholeEther() public {
//         // Try to stake 0.5 ETH (should fail)
//         vm.prank(alice);
//         vm.expectRevert(abi.encodeWithSignature("INVALID_AMOUNT()"));
//         stakingContract.stake{value: 0.5 ether}();
        
//         // Try to stake 1.5 ETH (should fail)
//         vm.prank(alice);
//         vm.expectRevert(abi.encodeWithSignature("INVALID_AMOUNT()"));
//         stakingContract.stake{value: 1.5 ether}();
//     }
    
//     // Test staking multiple times (should override previous stake and mint new NFT)
//     function testMultipleStakes() public {
//         // First stake 1 ETH
//         vm.prank(alice);
//         stakingContract.stake{value: 1 ether}();
        
//         // Check first NFT was minted
//         assertEq(stakingContract.ownerOf(1 ether), alice, "Alice should own the first NFT");
        
//         // Stake again with 2 ETH (mints a new NFT)
//         vm.prank(alice);
//         stakingContract.stake{value: 2 ether}();
        
//         // Check the stake was updated
//         (, uint256 amount) = stakingContract.stakes(alice);
//         assertEq(amount, 2 ether, "Stake should be updated to 2 ETH");
        
//         // Check that Alice owns both NFTs
//         assertEq(stakingContract.ownerOf(1 ether), alice, "Alice should own the first NFT");
//         assertEq(stakingContract.ownerOf(2 ether), alice, "Alice should own the second NFT");
//         assertEq(stakingContract.balanceOf(alice), 2, "Alice should have 2 NFTs");
//     }
// }
