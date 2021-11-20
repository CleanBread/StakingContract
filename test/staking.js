const Staking = artifacts.require('Staking');
const ERC20Rewards = artifacts.require('ERC20Rewards');
const { BN, time } = require('@openzeppelin/test-helpers');

contract('Staking', ([alice]) => {
  const ONE = new BN('1000000000000000000');
  const DAY = new BN(86400);

  let stakingInstance;
  let ERC20RewardsInstance;

  beforeEach(async () => {
    ERC20RewardsInstance = await ERC20Rewards.new({
      from: alice,
    });
    stakingInstance = await Staking.new(ERC20RewardsInstance.address, {
      from: alice,
    });
    await ERC20RewardsInstance.transferOwnership(stakingInstance.address, {
      from: alice,
    });
  });

  context('test staking', () => {
    it('test', async () => {
      await stakingInstance.stake({
        from: alice,
        value: ONE,
      });

      time.increase(DAY);

      await stakingInstance.harvest({ from: alice });
      await stakingInstance.harvest({ from: alice });
      const balance = await ERC20RewardsInstance.balanceOf(alice, {
        from: alice,
      });
      console.log(balance.toString(), 'balance');
    });
  });
});
