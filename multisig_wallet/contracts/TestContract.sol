// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TestContract {
    uint256 public value;
    
    event ValueSet(uint256 newValue);
    
    function setValue(uint256 _value) external payable {
        value = _value;
        emit ValueSet(_value);
    }
    
    function revertFunction() external pure {
        revert("Test revert");
    }
    
    function getData() external view returns (uint256) {
        return value;
    }
    
    receive() external payable {
        // Accept ETH
    }
}