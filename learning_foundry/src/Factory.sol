// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Counter} from "./Counter.sol";

contract CounterFactory {

    uint256 public counterCount;

    mapping(uint256 => address) public counters;

    function deployCounter() public returns (address) {
        
        uint256 _newCount = counterCount + 1;
        Counter _newCounter =  new Counter();
        counters[_newCount] = address(_newCounter);
        counterCount = _newCount;
        return address(_newCounter);
        
        
    }
}