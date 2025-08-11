// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/MultisigWallet.sol";

contract MultisigWalletTest is Test {
    MultisigWallet public multisig;
    address[] public owners;
    uint256 public requiredConfirmations = 2;
    
    // Test addresses
    address alice = address(0x1);
    address bob = address(0x2);
    address nonOwner = address(0x99);
    
    function setUp() public {
        owners = [alice, bob];
        vm.prank(alice);
        multisig = new MultisigWallet(owners, requiredConfirmations);
        vm.deal(address(multisig), 10 ether);
    }
    
    // Helper function to submit a transaction
    function _submitTransaction() internal returns (uint256) {
        vm.prank(alice);
        multisig.submitTransaction(address(0x123), 1 ether, "");
        return 0; // First transaction has ID 0
    }
    
    // Test onlyOwner modifier
    function test_OnlyOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("INVALID_ADDRESS(address)", nonOwner));
        multisig.submitTransaction(address(0x123), 1 ether, "");
    }
    
    // Test txExists modifier
    function test_TxExists() public {
        // Try to confirm non-existent transaction
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("NON_EXISTING_TX(uint256)", 0));
        multisig.confirmTransaction(0);
        
        // Submit a transaction and try with invalid ID
        _submitTransaction();
        
        // Try with invalid transaction ID
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("NON_EXISTING_TX(uint256)", 1));
        multisig.confirmTransaction(1);
    }
    
    // Test notConfirmed modifier
    function test_NotConfirmed() public {
        // Submit a transaction
        _submitTransaction();
        
        // First confirmation should work
        vm.prank(alice);
        multisig.confirmTransaction(0);
        
        // Second confirmation from same address should fail
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("TX_ALREADY_CONFIRMED(uint256)", 0));
        multisig.confirmTransaction(0);
    }
    
    // Test notExecuted modifier
    function test_NotExecuted() public {
        // Submit and confirm transaction
        _submitTransaction();
        
        // First confirmation from alice
        vm.prank(alice);
        multisig.confirmTransaction(0);
        
        // Second confirmation from bob
        vm.prank(bob);
        multisig.confirmTransaction(0);
        
        // Verify we have 2 confirmations (one from alice, one from bob)
        (,,, bool isExecuted, uint256 confirmations) = multisig.getTransaction(0);
        assertEq(isExecuted, false);
        assertEq(confirmations, 2);
        
        // Execute the transaction
        vm.prank(alice);
        multisig.executeTransaction(0);
        
        // Verify execution
        (,,, isExecuted, confirmations) = multisig.getTransaction(0);
        assertEq(isExecuted, true);
        assertEq(confirmations, 2);
        
        // Try to confirm again should fail with already confirmed
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("TX_ALREADY_CONFIRMED(uint256)", 0));
        multisig.confirmTransaction(0);
        
        // Try to execute again should fail with already executed
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("TX_ALREADY_EXECUTED(uint256)", 0));
        multisig.executeTransaction(0);
    }
    
    // Test full workflow
    function test_Workflow() public {
        // Submit transaction
        _submitTransaction();
        
        // Verify transaction was created
        (
            address to, 
            uint256 value, 
            bytes memory data, 
            bool executed, 
            uint256 confirmations
        ) = multisig.getTransaction(0);
        
        assertEq(to, address(0x123));
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(confirmations, 0);
        
        // First confirmation
        vm.prank(alice);
        multisig.confirmTransaction(0);
        
        // Verify confirmation
        (,,, executed, confirmations) = multisig.getTransaction(0);
        assertEq(executed, false);
        assertEq(confirmations, 1);
        
        // Second confirmation
        vm.prank(bob);
        multisig.confirmTransaction(0);
        
        // Verify confirmations
        (,,, executed, confirmations) = multisig.getTransaction(0);
        assertEq(executed, false);
        assertEq(confirmations, 2);
        
        // Execute the transaction
        vm.prank(alice);
        multisig.executeTransaction(0);
        
        // Verify execution
        (,,, executed, confirmations) = multisig.getTransaction(0);
        assertEq(executed, true);
        assertEq(confirmations, 2);
        
        // Check that the transaction was executed with the correct parameters
        // (This would require additional setup to verify the actual call was made)
        // For now, we just verify the transaction is marked as executed
    }
}
