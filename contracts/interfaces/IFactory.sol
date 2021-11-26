//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IFactory {
    event CreateDeal(address indexed _personA, address indexed _personB, uint256 _time);
    function createDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) external returns (address option);
    function getDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) external view returns(address);
    function getFee()external view returns(uint256);
    function getFeeTo()external view returns(address);
    function deposit(address token, address from, uint256 amount) external;
}