// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IFRC759 {
    event Transfer(address indexed _from, address indexed _to, uint256 amount, uint256 tokenStart, uint256 tokenEnd);
    event ApprovalForAll(address indexed _owner, address indexed _spender, uint256 _approved);
    function sliceOf(address _owner) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);
    function balanceOf(address from) external view returns (uint256);
    function timeBalanceOf(address _owner, uint256 tokenStart, uint256 tokenEnd) external view returns (uint256);
    function approve(address _spender, uint256 amount) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 amount) external returns (bool);
    function timeSliceTransferFrom(address _from, address _to, uint256 amount, uint256 tokenStart, uint256 tokenEnd) external;
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}