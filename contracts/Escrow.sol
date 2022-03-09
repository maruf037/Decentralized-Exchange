//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//This is the interface for the ERC20 token. We don't need the entire implementation to be able to trade with tokens.
interface IERC20 {
    function transfer(address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//This is the escrow contract, which will be used to manage the funds of each user.
contract Escrow {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, 'You must be the owner to execute this function');
        _;
    }

    /// @notice This contract does not accept ETH transfers function() external { revert(); }
    /// @notice To setup the initial tokens that the user will store when creating the escrow.
    /// @param _owner The address that will be the owner of this escrow, must be the owner of the tokens.

    //This is the constructor for the escrow contract.
    constructor (address _owner) public {
        require(_owner != address(0), 'The owner of the escrow cannot be the zero address. The owner must be set');
        owner = _owner;
    }

    /// @notice To transfer tokens to another address, usually the buyer or seller of an existing order.
    /// @param _token The adderss of the token to transfer.
    /// @param _to The address of the receiver.
    /// @param _amount The amount of tokens to transfer.
    function transferTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        require(_token != address(0), 'The token address cannot be the zero address. The token address must be set');
        require(_to != address(0), 'The receiver address cannot be the zero address. The receiver address must be set');
        require(_amount > 0, 'You must specify the amount of tokens to transfer');

        require(IERC20(_token).transfer(_to, _amount), 'The transfer must be successful');
    }

    /// @notice To see how many of a particular token this contract contains.
    /// @param _token The address of the token to check.
    /// @return uint256 The number of tikens this contract contrains.
    function checkTokenBalance(address _token) public view returns(uint256) {
        require(_token != address(0), 'The token address cannot be the zero address. The token address must be set');
        return IERC20(_token).balanceOf(address(this));
    }
}