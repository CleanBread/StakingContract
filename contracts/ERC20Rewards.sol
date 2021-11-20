pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Rewards is ERC20, Ownable {
    constructor() ERC20("ERC20Rewards", "EFS") {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
