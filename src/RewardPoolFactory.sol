// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardPoolFactory {
    address[] public deployedRewardPools;
    mapping(address => address) public operatorToPool;

    event RewardPoolDeployed(address indexed operator, address rewardPool, string name, string symbol);

    function deployRewardPool(string memory _name, string memory _symbol) external {
        require(operatorToPool[msg.sender] == address(0), "Operator already has a pool");

        mtfBTCRewardPool newPool = new mtfBTCRewardPool(_name, _symbol);
        deployedRewardPools.push(address(newPool));
        operatorToPool[msg.sender] = address(newPool);

        emit RewardPoolDeployed(msg.sender, address(newPool), _name, _symbol);
    }

    function getDeployedPools() external view returns (address[] memory) {
        return deployedRewardPools;
    }
}
