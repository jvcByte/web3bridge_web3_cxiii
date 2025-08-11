// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "./ERC20.sol";

contract ERC20Factory {
    ERC20 erc20;
    // Events
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint8 decimals,
        uint256 totalSupply
    );

    // Storage
    address[] public deployedTokens;
    mapping(address => address[]) public userTokens;
    mapping(address => TokenInfo) public tokenInfo;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address creator;
        uint256 createdAt;
    }

    // Modifiers
    modifier validTokenParams(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        _;
    }

    /**
     * @dev Creates a new ERC20 token
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _decimals Token decimals
     * @param _totalSupply Initial total supply
     * @param _initialOwner Address that will receive the initial supply
     * @return tokenAddress Address of the newly created token
     */
    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _initialOwner
    ) 
        public 
        validTokenParams(_name, _symbol, _totalSupply)
        returns (address tokenAddress) 
    {
        require(_initialOwner != address(0), "Initial owner cannot be zero address");
        
        // Deploy new ERC20 token
        ERC20 newToken = new ERC20(
            _name,
            _symbol,
            _decimals,
            _totalSupply,
            _initialOwner
        );

        tokenAddress = address(newToken);

        // Store token information
        deployedTokens.push(tokenAddress);
        userTokens[msg.sender].push(tokenAddress);
        
        tokenInfo[tokenAddress] = TokenInfo({
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            totalSupply: _totalSupply,
            creator: msg.sender,
            createdAt: block.timestamp
        });

        emit TokenCreated(
            tokenAddress,
            msg.sender,
            _name,
            _symbol,
            _decimals,
            _totalSupply
        );

        return tokenAddress;
    }

    /**
     * @dev Convenience function to create token with creator as initial owner
     */
    function createTokenForSelf(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) external returns (address) {
        return createToken(_name, _symbol, _decimals, _totalSupply, msg.sender);
    }

    // View functions
    function getDeployedTokensCount() external view returns (uint256) {
        return deployedTokens.length;
    }

    function getUserTokensCount(address _user) external view returns (uint256) {
        return userTokens[_user].length;
    }

    function getUserTokens(address _user) external view returns (address[] memory) {
        return userTokens[_user];
    }

    function getAllDeployedTokens() external view returns (address[] memory) {
        return deployedTokens;
    }

    function getTokenInfo(address _tokenAddress) external view returns (TokenInfo memory) {
        return tokenInfo[_tokenAddress];
    }
}
