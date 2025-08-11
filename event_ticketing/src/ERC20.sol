// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    // owner => spender => amount (fixed the comment)
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _initialOwner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[_initialOwner] = _totalSupply;
        emit Transfer(address(0), _initialOwner, _totalSupply);
    }

    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        isAddressValid(_to);
        isFundSufficient(msg.sender, _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        isAddressValid(_from);
        isAddressValid(_to);
        isFundSufficient(_from, _amount);
        if (allowances[_from][msg.sender] < _amount) {
            revert("Allowance exceeded!");
        }
        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowances[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(
        address _spender,
        uint256 _amount
    ) external returns (bool) {
        isAddressValid(_spender);
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    // ------  Helper Functions  ------
    function isAddressValid(address _address) internal pure {
        if (_address == address(0)) {
            revert("Invalid address!");
        }
    }

    function isFundSufficient(address _account, uint256 _amount) internal view {
        if (balances[_account] < _amount || _amount <= 0) {
            revert("Insufficient balance!");
        }
    }
}