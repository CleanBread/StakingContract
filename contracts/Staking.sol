pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Rewards.sol";

contract Staking is Ownable {
    IERC20Rewards private ERC20Rewards;

    struct Stake {
        uint256 value;
        uint32 stakeStartTime;
        uint32 getRewardsTime;
    }

    uint256 MIN_STAKE = 0.1 ether;
    uint8 ERC20_AMOUNT_PER_DAY = 100;
    uint32 DAY = 1 days;
    uint32 MONTH = DAY * 30;
    uint8 MAX_PERCENT = 50;

    mapping(address => Stake) public stakes;

    event Unstake(uint256 value);
    event UnstakeCommision(uint256 value);

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

    function stake() public payable {
        require(msg.value > 0, "Stake for zero amount");
        require(msg.value > MIN_STAKE, "Stake less than 0.1 ether");

        uint256 wholePart = msg.value / MIN_STAKE;
        require(
            wholePart * MIN_STAKE == msg.value,
            "Value is not a multiple of 0.1 ether"
        );

        if (stakes[msg.sender].value > 0) {
            harvest();
            stakes[msg.sender].value += msg.value;
        } else {
            Stake memory newStake = Stake(
                msg.value,
                uint32(block.timestamp),
                uint32(block.timestamp)
            );
            stakes[msg.sender] = newStake;
        }
    }

    function unstake(uint256 _value) public payable {
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

        require(unstakeAmount > 0, "unstake for zero amount");

        harvest();

        activeStake.value -= unstakeAmount + toStakeOwnerAmount;
        activeStake.stakeStartTime = 0;

        payable(msg.sender).transfer(unstakeAmount);

        emit Unstake(unstakeAmount);

        if (toStakeOwnerAmount > 0) {
            payable(owner()).transfer(toStakeOwnerAmount);
            emit UnstakeCommision(toStakeOwnerAmount);
        }
    }
}
