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

    // Then, add the onlyOwner modifier, the fallback function which reverts, and the constructor.
    modifier onlyOwner {
        require(msg.sender == owner, 'This sender must be the owner for this function');
        _;
    }

    // @notice Users should not send ether to this contract.
    function() externel {
        revert();
    }

    constructor() public {
        owner = msg.sender;
    }

    /* Define the whitelisting token function with the complete NatSpec documentation and the function signature. 
    I've highlighted the function so that you can clearly differentiate the function from the comments. */

    /// @notice to whitelist a token so that is tradable in the exchange.
    /// @dev If the transaction reverts, it could be because of the quantity of token pairs, try reducing the number and breaking the transaction into several pieces.
    /// @param _symbol The symbol of the token to be whitelisted.
    /// @param _token The token to whitelist, for instance 'TOK'.
    /// @param _tokenPairSymbols The token pairs to whitelist for this new token, for instance ['BAT', 'HYDRO'] which will be converted to ['TOK', 'BAT'] and ['TOK', 'HYDRO]
    /// @param _tokenPairAddresses The pair addresses to whitelist for this new token, for instance: ['0x213...', '0x927...', '0x128...'].
    function whitelistToken(
        bytes32 _symbol, 
        address _token, 
        bytes32[] memory _tokenPairSymbols, 
        address[] memory _tokenPairAddresses
        ) public onlyOwner{} 

    // To manage tokens, create the following two functions with the documentation.

    /// @notice To store tokens inside the escrow contract associated with the user accounts as long as the users made an approval beforehand.
    /// @dev It will revert is the if the user doesn't approve tokens beforehand to this contract.
    /// @param _token The token address
    /// @param _amount The quantity to deposit to the escrow contract.
    function depositTokens(address _token, uint256 _amount) public {}

    /// @notice To extract tokens.
    /// @param _token The token address to extract.
    /// @param _amount The amount of tokens to transfer.
    function extractTokens(address _token, uint256 _amount) public {}

    /* Add the market and limit the order functions with the parameters required for them to
    work properly, since these will be the main functions used to create orders and to interact
    with the DAX */
    /// @notice To create a market order by filling one or more existing limit orders at the most profitable price given a token pair,
    /// type of order (buy or sell) and the amount of tokens to trade, the _quantity is how many _firstSymbol tokens you want to buy if
    /// it's a buy order or how many _firstSymbol tokens you want to sell at market price.
    /// @param _type The type of order either 'buy' or 'sell'.
    /// @param _firstSymbol The first token to buy or sell.
    /// @param _secondSymbol The second token to create a pair.
    /// @param _quantity The amount of tokens to sell or buy.
    function marketOrder(bytes32 _type, bytes32 _firstSymbol, bytes32 _secondSymbol, uint256 _quantity) public {}

    /// @notice To create a market order given a token pair, type of order, amount of tokens to trade and the price per token. If
    /// the type is buy, the price will determine how many _secondSymbol tokens you are willing to pay for each _firstSymbol up until
    /// your _quantity or better if there are more profitable prices. If the type if sell, the price will determine how many _secondSymbol
    /// tokens you get for each _firstSymbol.
    /// @param _type The type of order either 'buy' or 'sell'.
    /// @param _firstSymbol The first symbol to deal with.
    /// @param _secondSymbol The second symbol that you want to deal
    /// @param _quantity How many tokens you want to deal, these are _firstSymbol tokens.
    /// @param _pricePerToken How many tokens you get or pay for your other symbol, the total price is _pricePerToken * _quantity.
    function limitOrder(bytes32 _type, bytes32 _firstSymbol, bytes32 _secondSymbol, uint256 _quantity, uint256 _pricePerToken) public {}
        
    /* Finally, add the view functions that you'll use as helpers and getters for important variables that your interface may need. */
    /// @notice sorts the selected array of orders by price from lower to higher if it's a buy order or from highest to lowest if it's a sell order.
    /// @param _type The type of order either 'buy' or 'sell'.
    /// @return uint256[] Returns the sorted ids.
    function sortIdsByPrices(bytes32 _type) public view returns (uint256[] memory) {}

    /// @notice Checks if a pair is valid.
    /// @param _firstSymbol The first symbol of the pair.
    /// @param _secondSymbol The second symbol of the pair.
    /// @return bool if the pair is valid or not.
    function checkValidPair(bytes32 _firstSymbol, bytes32 _secondSymbol) public view returns(bool) {}

    /// @notice Returns the token pairs
    /// @param _token To get the array of token pair for that selected token.
    /// @return bytes32[] An array containing the pairs.
    function getTokenPairs(bytes32 _token) public view returns(bytes32[]) {}
}   

