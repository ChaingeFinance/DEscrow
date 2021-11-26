//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

// import "hardhat/console.sol";

import './BusinessDeal.sol';

import './interfaces/IFactory.sol';

import './Ownable.sol';

contract Factory is IFactory, Ownable {

    mapping (bytes32 => address) business;

    mapping (address => bool) public isDeal;

    address[] public allDeal;

    uint256 public fee = 995;

    address public feeTo;

    bytes4 SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    constructor() {
    }

    function createDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) public override returns (address businessDeal) {
        require( _personA  != address(0) , 'Chainge: ZERO_ADDRESS');
        require( _personB  != address(0) , 'Chainge: ZERO_ADDRESS');
        require( _tokenA   != address(0) , 'Chainge: ZERO_ADDRESS');
        require( _tokenB   != address(0) , 'Chainge: ZERO_ADDRESS');

        bytes memory bytecode = type(BusinessDeal).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(_personA, _personB, time));

        assembly {
            businessDeal := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        isDeal[businessDeal] = true;

        allDeal.push(businessDeal);

        bytes32 tokenHash = keccak256(abi.encodePacked(_personA, _personB, _dealToken, dealAmount, _tokenA, _tokenB, _tokenAAmount, _tokenBAmount, time));
         
        require(business[tokenHash]  == address(0), 'Chainge: deal is existed');

        business[tokenHash] = businessDeal;

        BusinessDeal(businessDeal).initialize(_personA, _personB, _dealToken, dealAmount, _tokenA, _tokenB, _tokenAAmount, _tokenBAmount, time);

        feeTo = owner();
        
        emit CreateDeal(_personA, _personB, time);
    }

    function getDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) public view override returns(address) {
        bytes32 tokenHash = keccak256(abi.encodePacked(_personA, _personB, _dealToken, dealAmount,  _tokenA, _tokenB, _tokenAAmount, _tokenBAmount, time));
        return business[tokenHash];
    }

    function setFeeTo(address to) public onlyOwner {
        feeTo = to;
    }

    function getFeeTo() public view override returns(address) {
        return feeTo;
    }
    // Setting of fee. If you set a fee of 0.5%, then fee = 995
    function setFee(uint8 _fee) public onlyOwner {
        fee = _fee;
    }

    function getFee() public view override returns(uint256) {
        return fee;
    }

    // 代理扣钱, 只能由deal合约调用。
    function deposit(address token, address from, uint256 amount) public override {
        require( isDeal[msg.sender] == true, 'Factory: deal deposit error!');
        _safeTransfer(token, from, msg.sender, amount);
    }

    function _safeTransfer(address _token, address _from, address _to, uint value) private {        
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _from, _to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Factory: transfer failed');
    }
}