// SPDX-License-Identifier: ChaingeFinance
pragma solidity ^0.8.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface ISlice {
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function startTime() external view returns(uint256); 
    function endTime() external view returns(uint256); 
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function initialize(string memory name, string memory symbol, uint8 decimals, uint256 start, uint256 end) external;
    function approveByParent(address owner, address spender, uint256 amount) external returns (bool);
    function transferByParent(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Slice is Context, ISlice {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _start;
    uint256 private _end;

    bool private initialized;

    address public parent;

    constructor () {}

    function initialize(string memory name_, string memory symbol_, uint8 decimals_, uint256 start_, uint256 end_) public override {
        require(initialized == false, "Slice: already been initialized");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _start = start_;
        _end = end_;
        parent = _msgSender();
        
        initialized = true;
    }

    modifier whenNotPaused() {
        require(IFRC759(parent).paused() == false, "Slice: contract paused");
        _;
    }

    modifier whenAllowSliceTransfer() {
        require(IFRC759(parent).allowSliceTransfer() == true, "Slice: slice transfer not allowed");
        _;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function startTime() public view override returns(uint256) {
        return _start;
    }
    
    function endTime() public view override returns(uint256) {
        return _end;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveByParent(address owner, address spender, uint256 amount) public virtual override returns (bool) {
        require(_msgSender() == parent, "Slice: caller must be parent");
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenAllowSliceTransfer override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Slice: too less allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override whenAllowSliceTransfer returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferByParent(address sender, address recipipent, uint256 amount) public virtual override returns (bool) {
        require(_msgSender() == parent, "Slice: caller must be parent");
        _transfer(sender, recipipent, amount);
        return true;
    }

    function mint(address account, uint256 amount) public virtual override {
        require(_msgSender() == parent, "Slice: caller must be parent");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public override {
        require(_msgSender() == parent, "Slice: caller must be parent");
        require(balanceOf(account) >=  amount, "Slice: burn amount exceeds balance");
        _burn(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual whenNotPaused {
        require(IFRC759(parent).blocked(sender) == false, "Slice: sender blocked");
        require(IFRC759(parent).blocked(recipient) == false, "Slice: recipient blocked");
        require(sender != address(0), "Slice: transfer from the zero address");
        require(recipient != address(0), "Slice: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "Slice: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual whenNotPaused {
        require(owner != address(0), "Slice: approve from the zero address");
        require(spender != address(0), "Slice: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal virtual whenNotPaused {
        require(IFRC759(parent).blocked(account) == false, "Slice: account blocked");
        require(account != address(0), "Slice: mint to the zero address");
        require(amount > 0, "Slice: invalid amount to mint");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual whenNotPaused {
        _balances[account] = _balances[account].sub(amount, "Slice: transfer amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }
}

interface IFRC759 {
    event DataDelivery(bytes data);
    event SliceCreated(address indexed sliceAddr, uint256 start, uint256 end);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function maxSupply() external view returns (uint256);

    function createSlice(uint256 start, uint256 end) external returns(address);
    function sliceByTime(uint256 amount, uint256 sliceTime) external;
    function mergeSlices(uint256 amount, address[] calldata slices) external;
    function getSlice(uint256 start, uint256 end) external view returns(address);

    function paused() external view returns(bool);
    function blocked(address account) external view returns(bool);
    function allowSliceTransfer() external view returns(bool);
}

contract FRC759 is Context, IFRC759 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    address public fullTimeToken;

    bool internal _paused;
    bool internal _allowSliceTransfer;
    mapping (address => bool) internal _blockList;

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _maxSupply = maxSupply_;

        fullTimeToken = createSlice(MIN_TIME, MAX_TIME);
    }

    uint256 public constant MIN_TIME = 0;
    uint256 public constant MAX_TIME = 18446744073709551615;

    mapping (uint256 => mapping( uint256 => address)) internal timeSlice;

    function paused() public override view returns(bool) {
        return _paused;
    }

    function allowSliceTransfer() public override view returns(bool) {
        return _allowSliceTransfer;
    }

    function blocked(address account) public override view returns (bool) {
        return _blockList[account];
    }

    function _setPaused(bool paused_) internal {
        _paused = paused_;
    }

    function _setSliceTransfer(bool allowed_) internal {
        _allowSliceTransfer = allowed_;
    }

    function _setBlockList(address account_, bool blocked_) internal {
        _blockList[account_] = blocked_;
    }

    function name() public override view  returns (string memory) {
        return _name;
    }
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    function decimals() public override view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    function maxSupply() public override view returns (uint256) {
        return _maxSupply;
    }

    function _mint(address account, uint256 amount) internal {
        if (_maxSupply != 0) {
            require(_totalSupply.add(amount) <= _maxSupply, "FRC759: maxSupply exceeds");
        }
        _totalSupply = _totalSupply.add(amount);
        ISlice(fullTimeToken).mint(account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        ISlice(fullTimeToken).burn(account, amount);
    }

    function _burnSlice(address account, uint256 amount, uint256 start, uint256 end) internal {
        address sliceAddr = timeSlice[start][end];
        require(sliceAddr != address(0), "FRC759: slice not exists");
        ISlice(sliceAddr).burn(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return ISlice(fullTimeToken).balanceOf(account);
    }

    function timeBalanceOf(address account, uint256 start, uint256 end) public view returns (uint256) {
        address sliceAddr = timeSlice[start][end];
        require(sliceAddr != address(0), "FRC759: slice not exists");
        return ISlice(sliceAddr).balanceOf(account);
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return ISlice(fullTimeToken).allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        return ISlice(fullTimeToken).approveByParent(_msgSender(), spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        ISlice(fullTimeToken).transferByParent(sender, recipient, amount);
        ISlice(fullTimeToken).approveByParent(sender, _msgSender(), 
        ISlice(fullTimeToken).allowance(sender, _msgSender()).sub(amount, "FRC759: too less allowance"));
        return true;
    }

    function transferFromData(address sender, address recipient, uint256 amount, bytes calldata data) public virtual returns (bool) {
        ISlice(fullTimeToken).transferByParent(sender, recipient, amount);
        ISlice(fullTimeToken).approveByParent(sender, _msgSender(), 
        ISlice(fullTimeToken).allowance(sender, _msgSender()).sub(amount, "FRC759: too less allowance"));
        emit DataDelivery(data);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        ISlice(fullTimeToken).transferByParent(_msgSender(), recipient, amount);
        return true;
    }

    function transferData(address recipient, uint256 amount, bytes calldata data) public virtual returns (bool) {
        ISlice(fullTimeToken).transferByParent(_msgSender(), recipient, amount);
        emit DataDelivery(data);
        return true;
    }

    function timeSliceTransferFrom(address sender, address recipient, uint256 amount, uint256 start, uint256 end) public virtual returns (bool) {
        address sliceAddr = timeSlice[start][end];
        require(sliceAddr != address(0), "FRC759: slice not exists");
        ISlice(sliceAddr).transferByParent(sender, recipient, amount);
        ISlice(fullTimeToken).approveByParent(sender, _msgSender(), 
            ISlice(fullTimeToken).allowance(sender, _msgSender()).sub(amount, "FRC759: too less allowance"));
	    return true;
    }

    function timeSliceTransfer(address recipient, uint256 amount, uint256 start, uint256 end)  public virtual returns (bool) {
        address sliceAddr = timeSlice[start][end];
        require(sliceAddr != address(0), "FRC759: slice not exists");
        ISlice(sliceAddr).transferByParent(_msgSender(), recipient, amount);
        return true;
    }

    function createSlice(uint256 start, uint256 end) public returns(address sliceAddr) {
       require(end > start, "FRC759: tokenEnd must be greater than tokenStart");
       require(end <= MAX_TIME, "FRC759: tokenEnd must be less than MAX_TIME");
       require(timeSlice[start][end] == address(0), "FRC759: slice already exists");
        bytes memory bytecode = type(Slice).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(start, end));
    
        assembly {
            sliceAddr := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(sliceAddr)) {revert(0, 0)}
        }

        ISlice(sliceAddr).initialize(string(abi.encodePacked("TF_", _name)), 
            string(abi.encodePacked("TF_", _symbol)), _decimals, start, end);
        
        timeSlice[start][end] = sliceAddr;

        emit SliceCreated(sliceAddr, start, end);
    }

    function sliceByTime(uint256 amount, uint256 sliceTime) public {
        require(sliceTime >= block.timestamp, "FRC759: sliceTime must be greater than blockTime");
        require(sliceTime < MAX_TIME, "FRC759: sliceTime must be smaller than blockTime");
        require(amount > 0, "FRC759: amount cannot be zero");

        address _left = getSlice(MIN_TIME, sliceTime);
        address _right = getSlice(sliceTime, MAX_TIME);

        if (_left == address(0)) {
            _left = createSlice(MIN_TIME, sliceTime);
        }
        if (_right == address(0)) {
            _right = createSlice(sliceTime, MAX_TIME);
        }

        ISlice(fullTimeToken).burn(_msgSender(), amount);

        ISlice(_left).mint(_msgSender(), amount);
        ISlice(_right).mint(_msgSender(), amount);
    }
    
    function mergeSlices(uint256 amount, address[] calldata slices) public {
        require(slices.length > 0, "FRC759: empty slices array");
        require(amount > 0, "FRC759: amount cannot be zero");

        uint256 lastEnd = MIN_TIME;
    
        for(uint256 i = 0; i < slices.length; i++) {
            uint256 _start = ISlice(slices[i]).startTime();
            uint256 _end = ISlice(slices[i]).endTime();
            require(slices[i] == getSlice(_start, _end), "FRC759: invalid slice address");
            require(lastEnd == 0 || _start == lastEnd, "FRC759: continuous slices required");
            ISlice(slices[i]).burn(_msgSender(), amount);
            lastEnd = _end;       
        }

        uint256 firstStart = ISlice(slices[0]).startTime();
        address sliceAddr;
        if(firstStart <= block.timestamp){
            firstStart = MIN_TIME;
        }

        if(lastEnd > block.timestamp) {
            sliceAddr = getSlice(firstStart, lastEnd);
            if (sliceAddr == address(0)) {
                sliceAddr = createSlice(firstStart, lastEnd);
            }
        }

        if(sliceAddr != address(0)) {
            ISlice(sliceAddr).mint(_msgSender(), amount);
        }
    }

    function getSlice(uint256 start, uint256 end) public view returns(address) {
        return timeSlice[start][end];
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Controller is Ownable {
    event ControllerAdded(address controller);
    event ControllerRemoved(address controller);
    mapping(address => bool) controllers;

    modifier onlyController {
        require(isController(_msgSender()), "no controller rights");
        _;
    }

    function isController(address _controller) public view returns (bool) {
        return _controller == owner() || controllers[_controller];
    }

    function addController(address _controller) public onlyOwner {
        controllers[_controller] = true;
        emit ControllerAdded(_controller);
    }

    function removeController(address _controller) public onlyOwner {
        controllers[_controller] = false;
        emit ControllerRemoved(_controller);
    }
}

contract FRC759Token is Controller, FRC759 {
    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _maxSupply) 
    FRC759(_name, _symbol, _decimals, _maxSupply) {}

    function mint(address account, uint256 amount) public onlyController {
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public onlyController {
       _burn(account, amount);
    }

    function burnSlice(address account, uint256 amount, uint256 start, uint256 end) public onlyController {
       _burnSlice(account, amount, start, end);
    }

    function pause() public onlyController {
        _setPaused(true);
    }
	
	function unpause() public onlyController {
        _setPaused(false);
    }

    function enableSliceTransfer() public onlyController {
        _setSliceTransfer(true);
    }
	
	function disableSliceTransfer() public onlyController {
        _setSliceTransfer(false);
    }

    function blockUser(address account) public onlyController {
        _setBlockList(account, true);
    }
	
	function unblockUser(address account) public onlyController {
        _setBlockList(account, false);
    }
}