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
