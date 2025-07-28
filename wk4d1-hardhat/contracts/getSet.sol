// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract GetSet {
    uint256 value;

    event ValueSet(uint256 newValue);

    function setValue(uint256 _value) public {
        value = _value;
        emit ValueSet(_value);
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}