//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import './interfaces/IFactory.sol';

// import "hardhat/console.sol";

contract BusinessDeal {
  
  event Deposit(address indexed from, uint256 indexed amount);

  address public factory;
     
  bytes4 SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

  struct Deal {
    address personA;
    address personB;
    address dealToken; // 交易的token
    uint256 dealAmount; // 交易的数量
    address tokenA;
    address tokenB;
    uint256 tokenAAmount;
    uint256 tokenBAmount;
    uint256 time;
  }

  Deal deal;

  uint256 status;

  mapping (address => bool) confirmAccept;
  
  mapping (address => bool) confirmCancel;

  constructor() public {
    factory = msg.sender;
  }

  function initialize(address _personA, address _personB, address _dealToken, uint256 _dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 _time) public {
    require(msg.sender == factory, 'ChaingeOption: FORBIDDEN');
    require(_tokenAAmount != 0 || _tokenBAmount != 0, 'The amount cannot be 0');
    deal = Deal( _personA, _personB, _dealToken, _dealAmount, _tokenA , _tokenB, _tokenAAmount,  _tokenBAmount, _time);


    _addDealToken();
    if( deal.tokenAAmount > 0) {
      IFactory(factory).deposit(deal.tokenA, deal.personA, deal.tokenAAmount);
    }
    status = 1;
  }

  function currentState() public view returns(uint256){
    return status;
  }

  function _addDealToken() internal {
      IFactory(factory).deposit(deal.dealToken, deal.personA, deal.dealAmount);
  }

  function _withdrawDealToken() internal {
      _safeTransfer(deal.dealToken, address(this), deal.personA, deal.dealAmount);
  }

  function deposit () public {
    if(status == 1  && msg.sender == deal.personB) {
        if(deal.tokenBAmount > 0) {
          IFactory(factory).deposit(deal.tokenB, deal.personB, deal.tokenBAmount);
        }
        status = 2;
        emit Deposit(msg.sender, deal.tokenBAmount);
        return;
    }

    require(false, 'deposit: Abnormal transaction!');
  }

  function accept() public {
    require( msg.sender == deal.personA, 'accept: address illegal!');
    payment();
    status = 0; 
  }

  function cancel() public {
      if(status == 1 && msg.sender == deal.personA) {
        refund();
        status = 0; // 状态回归为0，
        return;
      }

      if(status == 2) {
        if(deal.personA == msg.sender && confirmCancel[deal.personB]) {
          refund();
          status = 0; // 状态回归为0，
        } else if(deal.personB == msg.sender && confirmCancel[deal.personA]) {
          refund();
          status = 0; // 状态回归为0，
        }
        else {
          confirmCancel[msg.sender] = true;
        }
        return;
      }
      require(false, 'cancel: Abnormal transaction!');
  }

  function payment() private {
    if( deal.tokenAAmount > 0) _safeTransfer(deal.tokenA, address(this), deal.personA, deal.tokenAAmount);
    if( deal.tokenBAmount > 0) _safeTransfer(deal.tokenB, address(this), deal.personB, deal.tokenBAmount);

    uint256 fee = IFactory(factory).getFee();
    address feeTo = IFactory(factory).getFeeTo();
    uint256 dealAmount =  deal.dealAmount;

    if(fee > 0 && feeTo != address(0)) {
      uint256 feeAmount =  ((deal.dealAmount * 1000) - (deal.dealAmount * fee)) / 1000;
      dealAmount = deal.dealAmount - feeAmount;
      _safeTransfer(deal.dealToken, address(this), feeTo, feeAmount);
    }

    _safeTransfer(deal.dealToken, address(this), deal.personB, dealAmount);
  }

  function refund() private {
    _withdrawDealToken();
    if (deal.tokenAAmount >0) _safeTransfer(deal.tokenA, address(this), deal.personA, deal.tokenAAmount);
    if (deal.tokenBAmount >0 && status == 2) _safeTransfer(deal.tokenB,  address(this), deal.personB, deal.tokenBAmount);
  }

  function _safeTransfer(address _token, address _from, address _to, uint value) private {
    (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _from, _to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'BusinessDeal: transfer failed');
  }
}
