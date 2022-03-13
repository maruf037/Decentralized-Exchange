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
    event TransferOrder(bytes32 _type, address indexed from, address indexed to, bytes32 tokenSymbol, uint256 quantity); // Shows the logs to people when a token is sold or purchased.
    enum OrderState {OPEN, CLOSED} // This defines whether an order is open or closed.

    //This struct defines the order. This struct has each property of each order to clearly define which token is being dealt.
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
    Order[] public buyOrders; // This is the array of buy orders.
    Order[] public sellOrders; // This is the array of sell orders.
    Order[] public closedOrders; // This is the array of closed orders.
    uint256 public orderIdCounter; // This is the counter for the order id.
    address public owner; // This is the owner of the contract.
    address public whitelistedTokens; // This is the token that is whitelisted.
    bytes32[] public whitelistedTokenSymbols; // This is the array of whitelisted tokens.
    address[] public users; // This is the array of users.

    //Create the mappings required for add and manage the token symbols and to find the orders by the given IDs.
    //This mapping is also helpful to find each specific order easily while optimizing gas costs.
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

    /// @notice Users should not send ether to this contract. 
    /// This fallback function that doesn't allow ETH transfers so that people don't send funds to this exchange.
    function() externel {
        revert();
    }

    /// @notice Constructor to setup the owner.
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
    // This function takes a token address, and an array of symbols to create pairs with that main token; that way, you're able to trade with a large quantity of pairs at once. 
    function whitelistToken(
        bytes32 _symbol, 
        address _token, 
        bytes32[] memory _tokenPairSymbols, 
        address[] memory _tokenPairAddresses
        ) public onlyOwner { 
            require(_token != address(0), 'Token address cannot be 0. You must specify the token address to whitelist');
            require(IERC20(_token).totalSupply() > 0, 'Token must have a total supply greater than 0. The token address specified is not a valid ERC20 token.');
            require(_tokenPairAddresses.length == _tokenPairSymbols.length, 'The number of token pair symbols must match the number of token pair addresses');

            // Add the token to the mapping of tokens.
            isTokenWhitelisted[_token] = true;
            isTokenSymbolWhitelisted[_symbol] = true;
            whitelistedTokens.push(_token);
            whitelistedTokenSymbols.push(_symbol);
            tokenAddressBySymbol[_symbol] = _token;
            tokenPairs[_symbol] = _tokenPairSymbols;

            for(uint256 i = 0; i < _tokenPairAddresses.length; i++) {
                address currentAddress = _tokenPairAddresses[i];
                bytes32 currentSymbol = _tokenPairSymbols[i];
                tokenPairs[currentSymbol].push(_symbol);
                if(!isTokenWhitelisted[currentAddress]) {
                    isTokenWhitelisted[currentAddress] = true;
                    isTokenSymbolWhitelisted[currentSymbol] = true;
                    whitelistedTokens.push(currentAddress);
                    whitelistedTokenSymbols.push(currentSymbol);
                    tokenAddressBySymbol[currentSymbol] = currentAddress;
                }
            }
        } 

    // To manage tokens, create the following two functions with the documentation.

    /// @notice To store tokens inside the escrow contract associated with the user accounts as long as the users made an approval beforehand.
    /// @dev It will revert is the if the user doesn't approve tokens beforehand to this contract.
    /// @param _token The token address
    /// @param _amount The quantity to deposit to the escrow contract.
    /* The depositTokens() function is used by users that want to increase their token balance. They can directly transfer the tokens they want 
     to trade to their associated Escrow contract, but users first have to create a new Escrow, which can only be done through this function. 
     Then the Escrow address will be associated with that account in the escrowByUserAddress mapping. This deposit function also requires that 
     the user previously uses the approve() function to allow the DAX contract to transfer tokens to the Escrow contract; otherwise, it will fail. */
    function depositTokens(address _token, uint256 _amount) public {
        require(isTokenWhitelisted[_token], 'The token to deposit must be whitelisted');
        require(_token != address(0), 'Token address cannot be 0. You must specify the token address to deposit');
        require(_amount > 0, 'Amount to deposit must be greater than 0. You must send some tokens with this deposit function.');
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, 'You must approve() the quantity of tokens to deposit first.');

        /* The deposit function checks whether the user has an Escrow contract associated with their address. If not, the function creates 
        a new Escrow, then transfers the deposit of tokens that the user requested as long as they previously approved some in the appropriate 
        ERC20 contract. */
        if(escrowByUserAddress[msg.sender] == address(0)) {
            Escrow newEscrow = new Escrow(address(this));
            escrowByUserAddress[msg.sender] = address(newEscrow);
            users.push(msg.sender);
        }
        IERC20(_token).transferFrom(msg.sender, escrowByUserAddress[msg.sender], _amount);
    }

    /// @notice To extract tokens.
    /// @param _token The token address to extract.
    /// @param _amount The amount of tokens to transfer.
    /* the extractTokens() function is used to move tokens from the Escrow to the user's address. It's a shortcut to the transferTokens() function 
    inside the Escrow contract to facilitate token management. */
    function extractTokens(address _token, uint256 _amount) public {
        /* The extract function is simply running the transferTokens() function to the owner's address, as long as they have some previous balance 
        inside. Otherwise it will revert.*/
        require(_token != address(0), 'Token address cannot be 0. You must specify the token address to extract');
        require(_amount > 0, 'Amount to extract must be greater than 0. You must send some tokens with this extract function.');
        Escrow(escrowByUserAddress[msg.sender]).transferTokens(_token, msg.sender, _amount);
    }

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
    function limitOrder(bytes32 _type, bytes32 _firstSymbol, bytes32 _secondSymbol, uint256 _quantity, uint256 _pricePerToken) public {
        address userEscrow = escrowByUserAddress[msg.sender];
        address firstSymbolAddress = tokenAddressBySymbol[_firstSymbol];
        address secondSymbolAddress = tokenAddressBySymbol[_secondSymbol];

        require(firstSymbolAddress != address(0), 'First symbol address cannot be 0. The first symbol has not bee whitelisted.');
        require(secondSymbolAddress != address(0), 'Second symbol address cannot be 0. The second symbol has not bee whitelisted.');
        require(isTokenSymbolWhitelisted[_firstSymbok]. 'The first symbol must be whitelisted to trade with it.');
        require(isTokenSymbolWhitelisted[_secondSymbol]. 'The second symbol must be whitelisted to trade with it.');
        require(userEscrow != address(0), 'You must deposit some tokens before creating orders, use depositToken().');
        require(checkValidPair(_firstSymbol, _secondSymbol), 'The pair must be a valid pair.');

        // After that, execute the buy functionality if the user is creating a buy limit order.
        Order memory myOrder = Order(orderIdCounter, msg.sender, _type, _firstSymbol, _secondSymbol, _quantity, _pricePerToken, now, OrderState.OPEN);
        orderByID[orderIdCounter] = myOrder;
        if(_type == 'buy') {
            // Check that the user has enough of the second symbol if he wants to buy the first symbol at that price.
            require(IERC20(secondSymbolAddress).balanceOf(userEscrow) => _quantity, 'You must have enough second token funds in your escrow contract to create this buy order.');
            buyOrders.push(myOrder);

            // Sort existing orders by price the most efficent way possible, we could optimize even more by creating a buy array for each token.
            uint256[] memory sortedIds = sortIdsByPrice('buy');
            delete buyOrders;
            buyOrders.length = sortedIds.length;
            for(uint256 i = 0; i < sortedIds.length; i++) {
                Order memory order = orderByID[sortedIds[i]];
                if(order.state == OrderState.OPEN) {
                    buyOrders[i] = orderById[sortedIds[i]];
                    buyOrderIndexById[sortedIds[i]] = i;
                } else {
                    // Check that the user has enough of the first symbol if he wonts to sell it for the second symbol.
                    require(IERC20(firstSymbolAddress).balanceOf(userEscrow) => order.quantity, 'You must have enough first token funds in your escrow contract to create this buy order.');

                    // Add the new order.
                    sellOrders.push(myOrder);

                    // Sort existing orders by price the most efficent way possible. we could optimize even more by creating a sell array for each token.
                    uint256[] memory sortedIds = sortIdsByPrice('sell');
                    delete sellOrders; //Reset orders.
                    sellOrders.length = sortedIds.length;
                    for(uint256 i = 0; i < sortedIds.length; i++) {
                        sellOrders[i] = orderByID[sortedIds[i]];
                        sellOrderIndexById[sortedIds[i]] = i;
                    }
                }
                orderIdCounter++;
            }
        }
    }
        
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

