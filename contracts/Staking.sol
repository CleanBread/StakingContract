pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Rewards.sol";

contract Staking {
    IERC20Rewards private ERC20Rewards;

    struct Stake {
        uint256 value;
        uint32 stakeStartTime;
        uint32 getRewardsTime;
    }

    uint256 MIN_STAKE = 0.1 ether;
    uint8 ERC20_AMOUNT_PER_DAY = 100;

    mapping(address => Stake) public stakes;

    constructor(address _token) {
        ERC20Rewards = IERC20Rewards(_token);
    }

    function harvest() public {
        require(stakes[msg.sender].value > 0, "Don't have yet active stake");

        uint256 rewardDays = (block.timestamp -
            stakes[msg.sender].getRewardsTime) / 1 days;

        uint256 rewards = uint256(ERC20_AMOUNT_PER_DAY) * rewardDays;

        stakes[msg.sender].getRewardsTime = uint32(block.timestamp);
        ERC20Rewards.mint(msg.sender, rewards);
    }

    function stake() public payable {
        require(msg.value > 0, "Stake for zero amount");
        require(msg.value > MIN_STAKE, "Stake less than 0.1 ether");

        uint256 wholePart = msg.value / MIN_STAKE;
        require(
            wholePart * MIN_STAKE == msg.value,
            "Value is not a multiple of 0.1 ether"
        );

        if (stakes[msg.sender].value > 0) {
            stakes[msg.sender].value += msg.value;
            harvest();
        } else {
            Stake memory newStake = Stake(
                msg.value,
                uint32(block.timestamp),
                uint32(block.timestamp)
            );
            stakes[msg.sender] = newStake;
        }
    }
}
