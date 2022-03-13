// Functions that we need:
/*
1. Constructor to setup the owner.
2. Fallback non-payable function to reject ETH from direct transfers since we only want people to use the Functions
designed to trade a spectific pair.
3. Function to extract tokens from this contract in case someone mistakenly sends ERC20 to the wrong function.
4. Function to create whitelist a token by the owner.
5. Function to create market orders.
6. Function to create limit orders.
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Escrow.sol';

//This is the interface for the ERC20 token. We don't need the entire implementation to be able to trade with tokens.
/*interface IERC20 {
    function transfer(address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
*/

contract DAX {
    event TransferOrder(bytes32 _type, address indexed from, address indexed to, bytes32 tokenSymbol, uint256 quantity);
    enum OrderState {OPEN, CLOSED}

    //This struct defines the order.
    struct Order {
        uint256 id;
        address ownner;
        bytes32 orderType;
        bytes32 firstSymbol;
        bytes32 secondSymbol;
        uint256 quantity;
        uint256 price;
        uint256 timestamp;
        OrderState state;
    }

    //Then define the many variables needed to manage sell and buy orders, while also whitelisting tokens.
    Order[] public buyOrders;
    Order[] public sellOrders;
    Order[] public closedOrders;
    uint256 public orderIdCounter;
    address public owner;
    address public whitelistedToken;
    bytes32[] public whitelistedTokenSymbols;
    address[] public users;

    //Create the mappings required for add and manage the token symbols and to find the orders by the given IDs.
    //Token address => whitelisted or not
    mapping(address => bool) public isTokenWhitelisted;
    mapping(address => bool) public isTokenSymbolWhitelisted;
    mapping(bytes32 => bytes32[]) public tokenPairs; // A token symbol pair made of 'FIRST' => 'SECOND'
    mapping(bytes32 => address) public tokenAddressBySymbol; // Symbol => address of the token
    mapping(uint256 => Order) public orderById; // Id => trade object
    mapping(uint256 => uint256) public buyOrderIndexById; // Id => index inside the buyOrders array
    mapping(uint256 => uint256) public sellOrderIndexById; // Id => index inside the sellOrders array
    mapping(address => address) public escrowByUserAddress; // User address => escrow contract address
}   
