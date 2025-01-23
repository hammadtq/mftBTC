// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/mftBTCRewardPool.sol";
import "../src/RewardPoolFactory.sol";
import "../src/Governance.sol";

contract mftBTCTests is Test {
    mftBTCRewardPool rewardPool;
    RewardPoolFactory factory;
    Governance governance;

    address user = address(0x123);
    address operator = address(0x456);

    function setUp() public {
        // Deploy Governance contract
        governance = new Governance();

        // Deploy RewardPoolFactory contract
        factory = new RewardPoolFactory();

        // Deploy a new RewardPool via the factory
        vm.prank(operator);
        factory.deployRewardPool("mtfBTC", "MTFBTC");

        // Get the deployed RewardPool address
        address rewardPoolAddress = factory.operatorToPool(operator);
        rewardPool = mftBTCRewardPool(rewardPoolAddress);
    }

    function testDepositAndMint() public {
        vm.prank(user);
        rewardPool.depositBTC(1000);

        assertEq(rewardPool.balanceOf(user), 1000);
        assertEq(rewardPool.totalBTCDeposited(), 1000);
    }

    function testRedeemBTC() public {
        vm.prank(user);
        rewardPool.depositBTC(1000);

        vm.prank(user);
        rewardPool.redeemBTC(500);

        assertEq(rewardPool.balanceOf(user), 500);
        assertEq(rewardPool.totalBTCDeposited(), 500);
    }

    function testGovernanceSetParameter() public {
        vm.prank(governance.admin());
        governance.setParameter("maxDeposit", 10000);

        assertEq(governance.parameters("maxDeposit"), 10000);
    }
}