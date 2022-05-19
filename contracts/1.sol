//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IFactory {
    event CreateDeal(address indexed _personA, address indexed _personB, uint256 _time);
    function createDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, uint256 _tokenAAmount,  address _tokenB, uint256 _tokenBAmount, uint256 time) external returns (address option);
    function getDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA,  uint256 _tokenAAmount, address _tokenB, uint256 _tokenBAmount, uint256 time) external view returns(address);
    function getFee(address token)external view returns(uint256);
    function getFeeTo()external view returns(address);
    function deposit(address token, address from, uint256 amount) external;
}

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BusinessDeal {
  
  event Deposit(address indexed from, uint256 indexed amount);

  address public factory;

  bytes4 SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
  
  struct Deal {
    address personA;
    address personB;
    address dealToken; 
    uint256 dealAmount;
    address tokenA;
    address tokenB;
    uint256 tokenAAmount;
    uint256 tokenBAmount;
    uint256 time;
  }

  Deal public deal;

  uint256 private status;

  mapping (address => bool) public confirmAccept;
  
  mapping (address => bool) public confirmCancel;

  constructor() public {
    factory = msg.sender;
  }

  function initialize(address _personA, address _personB, address _dealToken, uint256 _dealAmount, address _tokenA, uint256 _tokenAAmount, address _tokenB, uint256 _tokenBAmount, uint256 _time) public {
    require(msg.sender == factory, 'Chainge: FORBIDDEN');
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
    if( deal.dealAmount > 0) {
      IFactory(factory).deposit(deal.dealToken, deal.personA, deal.dealAmount);
    }
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
        status = 0;
        return;
      }

      if(status == 2) {
        if(deal.personA == msg.sender && confirmCancel[deal.personB]) {
          refund();
          status = 0;
        } else if(deal.personB == msg.sender && confirmCancel[deal.personA]) {
          refund();
          status = 0;
        }
        else {
          confirmCancel[msg.sender] = true;
        }
        return;
      }
      require(false, 'cancel: Abnormal transaction!');
  }

  function payment() private {
    if( deal.tokenAAmount > 0) _safeTransfer(deal.tokenA, deal.personA, deal.tokenAAmount);
    if( deal.tokenBAmount > 0) _safeTransfer(deal.tokenB, deal.personB, deal.tokenBAmount);

    uint256 fee;

    if(deal.tokenA == deal.tokenB) {
      fee = IFactory(factory).getFee(deal.tokenA);
    }else {
      fee = IFactory(factory).getFee(address(0));
    }

    address feeTo = IFactory(factory).getFeeTo();
    uint256 dealAmount =  deal.dealAmount;

    if(fee > 0 && feeTo != address(0)) {
      uint256 feeAmount =  ((deal.dealAmount * 1000) - (deal.dealAmount * fee)) / 1000;
      dealAmount = deal.dealAmount - feeAmount;
      _safeTransfer(deal.dealToken, feeTo, feeAmount);
    }

    _safeTransfer(deal.dealToken, deal.personB, dealAmount);
  }

  function refund() private {
    _withdrawDealToken();
    if (deal.tokenAAmount > 0 ) _safeTransfer(deal.tokenA, deal.personA, deal.tokenAAmount);
    if (deal.tokenBAmount > 0 && status == 2) _safeTransfer(deal.tokenB, deal.personB, deal.tokenBAmount);
  }

  function _withdrawDealToken() internal {
      if(deal.dealAmount > 0) {
        _safeTransfer(deal.dealToken, deal.personA, deal.dealAmount);
      }
  }

  // function _safeTransfer(address _token, address _to, uint value) private {
  //   (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _to, value));
  //   require(success && (data.length == 0 || abi.decode(data, (bool))), 'BusinessDeal: transfer failed');
  // }
  function _safeTransfer(address _token, address _to, uint value) private {
     IFRC759(_token).transfer(_to, value);
  }
}

contract Factory is IFactory, Ownable {

    mapping (bytes32 => address) business;

    mapping (address => bool) public isDeal;

    address[] public allDeal;

    uint256 public fee = 995;

    mapping (address => uint256) public customizeFee;

    address public feeTo;

    bytes4 SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    constructor() {
    }

    function createDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, uint256 _tokenAAmount, address _tokenB,  uint256 _tokenBAmount, uint256 time) public override returns (address businessDeal) {
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

        BusinessDeal(businessDeal).initialize(_personA, _personB, _dealToken, dealAmount, _tokenA,  _tokenAAmount,  _tokenB,_tokenBAmount, time);

        feeTo = owner();
        
        emit CreateDeal(_personA, _personB, time);
    }

    function getDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, uint256 _tokenAAmount, address _tokenB,  uint256 _tokenBAmount, uint256 time) public view override returns(address) {
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
    function setFee(uint256 _fee, address _token) public onlyOwner {
        if(_token == address(0)) {
              fee = _fee;
        }else{
            customizeFee[_token] = _fee;
        }
    }

    function getFee(address _token) public view override returns(uint256) {
        return _token == address(0) ? fee: customizeFee[_token];
    }

    function deposit(address token, address from, uint256 amount) public override {
        require(isDeal[msg.sender] == true, 'Factory: deal deposit error!');
        _safeTransfer(token, from, msg.sender, amount);
    }

    function _safeTransfer(address _token, address _from, address _to, uint value) private {        
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _from, _to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Factory: transfer failed');
    }
}