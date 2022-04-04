 /***
 * Utility to Lock
 ***/

 /***
 * All systems invented by ALLCOINLAB
 * https://github.com/ALLCOINLAB
 * https://t.me/ALLCOINLAB
 * 
 * The Web3 Project
 * TG: https://t.me/TheWeb3Project
 * Website: https://theweb3project.com
 * 
 *
 * Written in easy code to for easy verificiation by the investors.
 * Some are made with manual if-else conditions in order not to make mistake + maintain code easily.
 * Those doesn't cost gas much so this is way better than the simple / short code.
 * Used high gas optimization if needed.
 * 
 *
 * 
 * $$$$$$$$\ $$\                       $$\      $$\           $$\        $$$$$$\        $$$$$$$\                                                $$\     
 * \__$$  __|$$ |                      $$ | $\  $$ |          $$ |      $$ ___$$\       $$  __$$\                                               $$ |    
 *    $$ |   $$$$$$$\   $$$$$$\        $$ |$$$\ $$ | $$$$$$\  $$$$$$$\  \_/   $$ |      $$ |  $$ | $$$$$$\   $$$$$$\  $$\  $$$$$$\   $$$$$$$\ $$$$$$\   
 *    $$ |   $$  __$$\ $$  __$$\       $$ $$ $$\$$ |$$  __$$\ $$  __$$\   $$$$$ /       $$$$$$$  |$$  __$$\ $$  __$$\ \__|$$  __$$\ $$  _____|\_$$  _|  
 *    $$ |   $$ |  $$ |$$$$$$$$ |      $$$$  _$$$$ |$$$$$$$$ |$$ |  $$ |  \___$$\       $$  ____/ $$ |  \__|$$ /  $$ |$$\ $$$$$$$$ |$$ /        $$ |    
 *    $$ |   $$ |  $$ |$$   ____|      $$$  / \$$$ |$$   ____|$$ |  $$ |$$\   $$ |      $$ |      $$ |      $$ |  $$ |$$ |$$   ____|$$ |        $$ |$$\ 
 *    $$ |   $$ |  $$ |\$$$$$$$\       $$  /   \$$ |\$$$$$$$\ $$$$$$$  |\$$$$$$  |      $$ |      $$ |      \$$$$$$  |$$ |\$$$$$$$\ \$$$$$$$\   \$$$$  |
 *    \__|   \__|  \__| \_______|      \__/     \__| \_______|\_______/  \______/       \__|      \__|       \______/ $$ | \_______| \_______|   \____/ 
 *                                                                                                              $$\   $$ |                              
 *                                                                                                              \$$$$$$  |                              
 *                                                                                                               \______/                               
 * 
 * 
 * This is UpGradable Contract
 * So many new features will be applied periodically :)
 * 
 ***/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/proxy/utils/Initializable.sol"; 
import "./Initializable.sol";

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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract TheWeb3ProjectLock is Initializable {
    using SafeMath for uint256;

    address public _owner;

    uint256 _lockPortion;
    uint256 _lockStartTime;

    fallback() external payable {}
    receive() external payable {}
    
    modifier limited() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    // constructor(address owner_) {
    //     _owner = owner_;
    // }
    
    function initialize(address owner_) public initializer {
        _owner = owner_;
    }
    
    /*
     * This also supports rebase tokens
     * this doesnt need gas opt
     *
     * Make sure exclude from tax fees for this contract and the token sender
     * Contact https://t.me/ALLCOINLAB
     */
   
    // approve this contract first
    function lock(address token, uint256 amount) external limited {
        _lockStartTime = block.timestamp;
        _lockPortion = 60;

        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    // 600 / 60 * 1 = 10 (590 left, 59 set)
    // 590 / 59 * 1 = 10
    // (rebased double, 1180 / 59 * 1 = 20)
    function unlock(address token) external limited {
        require(_lockStartTime.add(60 * 60 * 24 * 7) < block.timestamp, "1 week should pass");
        uint bal = IERC20(token).balanceOf(address(this));
        uint balPortion = bal.div(_lockPortion);
        IERC20(token).transfer(msg.sender, balPortion);

        _lockPortion = _lockPortion.sub(1);
        _lockStartTime = _lockStartTime.add(60 * 60 * 24 * 7);
    }

}
