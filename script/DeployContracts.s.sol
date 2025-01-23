// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/mftBTCRewardPool.sol";
import "../src/RewardPoolFactory.sol";
import "../src/Governance.sol";

contract DeployContracts is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Governance contract
        Governance governance = new Governance();
        console.log("Governance deployed at:", address(governance));

        // Deploy RewardPoolFactory contract
        RewardPoolFactory factory = new RewardPoolFactory();
        console.log("RewardPoolFactory deployed at:", address(factory));

        // Deploy a new RewardPool via the factory
        factory.deployRewardPool("mtfBTC", "MTFBTC");
        address rewardPoolAddress = factory.operatorToPool(msg.sender);
        console.log("mftBTCRewardPool deployed at:", rewardPoolAddress);

        vm.stopBroadcast();
    }
}