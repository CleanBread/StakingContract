pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Rewards.sol";

contract Staking is Ownable {
    IERC20Rewards private immutable ERC20Rewards;

    struct Stake {
        uint256 value;
        uint32 stakeStartTime;
        uint32 getRewardsTime;
    }

    uint256 constant MIN_STAKE = 0.1 ether;
    uint8 constant ERC20_AMOUNT_PER_DAY = 100;
    uint32 constant DAY = 1 days;
    uint32 constant MONTH = DAY * 30;
    uint8 constant MAX_PERCENT = 50;

    mapping(address => Stake) public stakes;

    event UnstakeEvent(address to, uint256 value, uint256 commision);
    event StakeEvent(address who, uint256 value);

    constructor(address _token) {
        ERC20Rewards = IERC20Rewards(_token);
    }

    function harvest() public {
        Stake storage activeStake = stakes[msg.sender];

        uint256 rewardDays = (block.timestamp - activeStake.getRewardsTime) /
            uint256(DAY);

        if (rewardDays > 0) {
            uint256 rewardPerDay = (activeStake.value / MIN_STAKE) *
                uint256(ERC20_AMOUNT_PER_DAY);
            uint256 rewards = rewardPerDay * rewardDays;
            activeStake.getRewardsTime = uint32(block.timestamp);
            ERC20Rewards.mint(msg.sender, rewards);
        }
    }

    function stake() external payable {
        require(msg.value > 0, "Stake for zero amount");
        require(msg.value > MIN_STAKE, "Stake less than 0.1 ether");
        require(
            msg.value % MIN_STAKE == 0,
            "Value is not a multiple of 0.1 ether"
        );

        if (stakes[msg.sender].value > 0) {
            harvest();
            stakes[msg.sender].value += msg.value;
        } else {
            stakes[msg.sender] = Stake(
                msg.value,
                uint32(block.timestamp),
                uint32(block.timestamp)
            );
        }
        emit StakeEvent(msg.sender, msg.value);
    }

    function unstake(uint256 _value) external payable {
        require(
            _value % MIN_STAKE == 0,
            "Value is not a multiple of 0.1 ether"
        );
        Stake storage activeStake = stakes[msg.sender];
        require(activeStake.value > 0, "User don't have active stake");
        require(
            _value <= activeStake.value,
            "unstake value is greather than active stake value"
        );

        uint256 stakeSeconds = (block.timestamp - activeStake.stakeStartTime);
        uint256 stakedDays = stakeSeconds / uint256(DAY);

        uint256 unstakeAmount;
        uint256 toStakeOwnerAmount;

        if (stakedDays < 30) {
            unstakeAmount = (_value * uint256(MAX_PERCENT)) / 100;
            toStakeOwnerAmount = (_value * uint256(MAX_PERCENT)) / 100;
        } else if (stakedDays >= 60) {
            unstakeAmount = _value;
        } else {
            uint256 percent = ((stakeSeconds - uint256(MONTH)) *
                uint256(MAX_PERCENT)) / uint256(MONTH);
            toStakeOwnerAmount = (_value * percent) / 100;
            unstakeAmount = _value - toStakeOwnerAmount;
        }

        harvest();

        activeStake.value -= unstakeAmount + toStakeOwnerAmount;

        if (activeStake.value == _value) {
            activeStake.stakeStartTime = 0;
        }

        payable(msg.sender).transfer(unstakeAmount);

        emit UnstakeEvent(msg.sender, unstakeAmount, toStakeOwnerAmount);

        if (toStakeOwnerAmount > 0) {
            payable(owner()).transfer(toStakeOwnerAmount);
        }
    }
}
