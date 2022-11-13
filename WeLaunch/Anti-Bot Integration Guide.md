# Anti-Bot Integration Guide

```

interface ITools {
  function setTokenOwner(address owner) external;
  function beforeTransfer(address from, address to, uint amount) external;
}


// Your codes

contract YourToken {
  ITools public tools;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint totalSupply_,
    address tools_
  ) {
    // your codes
    
    // This code installs anti-bot system to your contract
    tools = ITools(tools_);
    // This code registers contract deployer to be controller of anti-bot system for this token
    // You can later change controller in our website
    tools.setTokenOwner(msg.sender);
  }

  // run anti-bot system before doing transfer, your dev will know where to put :)
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    tools.beforeTransfer(sender, recipient, amount);
    
    // your codes
  }
