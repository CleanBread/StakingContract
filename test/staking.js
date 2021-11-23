const Staking = artifacts.require('Staking');
const ERC20Rewards = artifacts.require('ERC20Rewards');

const { BN, time, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract('Staking', ([alice, bob]) => {
  const ZERO = new BN(0);
  const ONE = new BN('1000000000000000000');
  const TWO = new BN('2000000000000000000');
  const DAY = new BN(86400);
  const FOURTY_FIVE_DAYS = new BN(3888000);
  const TWO_MONTH = new BN(5184000);

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
    it('should be able to stake', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });

      const stake = await stakingInstance.stakes(bob, { from: bob });

      expect(stake.value).bignumber.equal(ONE);
    });

    it('should be able to add ether to active stake', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });

      const stake = await stakingInstance.stakes(bob, { from: bob });

      expect(stake.value).bignumber.equal(TWO);
    });

    it('should be able to get reward for 1 ether after add ether to active stake', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      const balanceBeforeHarvest = await ERC20RewardsInstance.balanceOf(bob, {
        from: bob,
      });
      expect(balanceBeforeHarvest).bignumber.equal(new BN(0));
      time.increase(DAY);
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      const balanceAfterHarvest = await ERC20RewardsInstance.balanceOf(bob, {
        from: bob,
      });
      expect(balanceAfterHarvest).bignumber.equal(new BN(1000));
    });

    it('should be able to unstake with 1 ether in active stake with 50% commision', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      const unstake = await stakingInstance.unstake(ONE, { from: bob });

      expectEvent(unstake, 'UnstakeEvent', {
        to: bob,
        value: '500000000000000000',
        commision: '500000000000000000',
      });

      const balanceERC20 = await ERC20RewardsInstance.balanceOf(bob, {
        from: bob,
      });
      expect(balanceERC20).bignumber.equal(new BN(0));
    });

    it('should be able to unstake with 1 ether in active stake with 25% commision', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      time.increase(FOURTY_FIVE_DAYS);
      const unstake = await stakingInstance.unstake(ONE, { from: bob });

      expectEvent(unstake, 'UnstakeEvent', {
        to: bob,
        value: '750000000000000000',
        commision: '250000000000000000',
      });
      const balanceERC20 = await ERC20RewardsInstance.balanceOf(bob, {
        from: bob,
      });
      expect(balanceERC20).bignumber.equal(new BN(45000));
    });

    it('should be able to unstake with 1 ether in active stake with 0% commision', async () => {
      await stakingInstance.stake({
        from: bob,
        value: ONE,
      });
      time.increase(TWO_MONTH);
      const unstake = await stakingInstance.unstake(ONE, { from: bob });

      expectEvent(unstake, 'UnstakeEvent', {
        to: bob,
        value: ONE,
        commision: ZERO,
      });

      const balanceERC20 = await ERC20RewardsInstance.balanceOf(bob, {
        from: bob,
      });
      expect(balanceERC20).bignumber.equal(new BN(60000));
    });
  });
});
