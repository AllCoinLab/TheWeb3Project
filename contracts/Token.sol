// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
 
interface IPcsF {
    function getPair(address tAdr, address bAdr) external view returns (address);
}
 
contract Token {
    using EnumerableSet for EnumerableSet.AddressSet;
 
    address public owner;
 
    string public name;
    string public symbol;
    uint public decimals;
 
    uint private _totalSupply;
 
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
 
 
 
    struct Params { 
        bool supplyable;
        uint maxSupply;
 
        bool pausable;
        bool paused;
 
        bool blacklistable;
        bool whitelistable;
 
    }
 
    struct Rates {
        uint buyBurnRate;
        uint buyDevRate;
 
        uint sellBurnRate;
        uint sellDevRate;
    }
    EnumerableSet.AddressSet private _blacklist;
    EnumerableSet.AddressSet private _whitelist;
 
    EnumerableSet.AddressSet private _pairs;
    Params public _params;
    Rates public _rates;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    fallback() external payable {}
    receive() external payable {}
 
    modifier onlyOwner() {
        require(owner == msg.sender, "limited usage");
        _;
    }
 
 
    constructor (
        address owner_, // if renounce, set 0
        string memory name_, 
        string memory symbol_, 
        uint decimals_,
        uint amount_,
        address[] memory adrs,
        uint[] memory uints,
        bool[] memory bools
        ) {
        owner = owner_;
 
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
 
        _totalSupply = amount_ * 10**decimals_;
        _balances[owner_] = amount_ * 10**decimals_;
        emit Transfer(address(0), owner_, amount_ * 10**decimals_);
 
        // params can only be set at the deploy
        _params.fAdr = adrs[0];
 
        _params.supplyable = bools[0];
        if (bools[0]) {
          _params.maxSupply = uints[0] * 10**decimals_;
        }
        _params.pausable = bools[1];
        _params.blacklistable = bools[2];
        _params.whitelistable = bools[3];
        _params.taxable = bools[4];
        if (bools[4]) {
          _rates.buyBurnRate = uints[1];
          _rates.buyDevRate = uints[2];
          _rates.sellBurnRate = uints[3];
          _rates.sellDevRate = uints[4];
        }
 
        
    }
 
    // basic
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner_, address spender) public view virtual returns (uint256) {
        return _allowances[owner_][spender];
    }
 
 
 
 
    // approve
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _spendAllowance(address owner_, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner_, spender, currentAllowance - amount);
        }
    }
    function _approve(address owner_, address spender, uint256 amount) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
 
 
 
    // transfer
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
 
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        amount = _beforeTokenTransfer(from, to, amount);
 
        _transferEvent(from, to, amount);
 
        amount = _afterTokenTransfer(from, to, amount);
    }
    function _transferEvent(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
 
        if (amount > 0) {
          _balances[from] -= amount;
          _balances[to] += amount;
        }
 
        emit Transfer(from, to, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns (uint) {
        Params memory params = _params;
 
        if (params.whitelistable) {
            if (_whitelist.contains(from)) {
                return amount;
            }
        }
 
        if (params.pausable) {
            require(!params.paused, "paused");
        }
        if (params.blacklistable) {
            require(!_blacklist.contains(from), "blacklist");
        }
 
        Rates memory rates = _rates;
        if (_pairs.contains(from)) { // buy
            _transferEvent(from, address(0xdead), amount * rates.buyBurnRate / 10000);
            _transferEvent(from, owner, amount * rates.buyDevRate / 10000);
        } else if (_pairs.contains(to)) { // sell
            _transferEvent(from, address(0xdead), amount * rates.sellBurnRate / 10000);
            _transferEvent(from, owner, amount * rates.sellDevRate / 10000);
        }
        from;
        to;
 
        return amount;
    }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual returns (uint) {
        Params memory params = _params;
 
        if (params.whitelistable) {
            if (_whitelist.contains(from)) {
                return amount;
            }
        }
 
        from;
        to;
 
        return amount;
    }
 
    
    /////////////////////////////////////////////////////////////////////////////////// special
    function transferMulti(address[] calldata adrs, uint[] calldata amounts) external { // not gas opt, following usual seq
        for (uint idx = 0; idx < adrs.length; idx++) {
            _transferEvent(msg.sender, adrs[idx], amounts[idx]);
        }
    }



    /////////////////////////////////////////////////////////////////////////////////// owner
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }
 
    function setPairs(address[] calldata fAdrs, address[] calldata bAdrs) external onlyOwner {
        for (uint idx = 0; idx < fAdrs.length; idx++) {
            address pair = IPcsF(fAdrs[idx]).getPair(address(this), bAdrs[idx]);
            if (_pairs.contains(pair)) {
                continue;
            }
 
            _pairs.add(pair);
        }
    }
 
    function incSup(uint amount) external onlyOwner {
        require(_params.supplyable, "supplyable");
 
        require(amount > 0, "amount is zero");
 
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        require(_totalSupply <= _params.maxSupply, "maxSupply");
 
        emit Transfer(address(0), msg.sender, amount);
    }
    function setPause(bool flag) external onlyOwner {
        _params.paused = flag;
    }
    function setBlacklists(address[] calldata adrs, bool[] calldata flags) external onlyOwner {
        for (uint idx = 0; idx < adrs.length; idx++) {
            if (flags[idx]) {
                _blacklist.add(adrs[idx]);
            } else {
                _blacklist.remove(adrs[idx]);
            }
        }
    }
    function setWhitelists(address[] calldata adrs, bool[] calldata flags) external onlyOwner {
        for (uint idx = 0; idx < adrs.length; idx++) {
            if (flags[idx]) {
                _whitelist.add(adrs[idx]);
            } else {
                _whitelist.remove(adrs[idx]);
            }
        }
    } 
}
