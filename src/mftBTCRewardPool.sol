// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mtfBTCRewardPool is ERC20, Ownable {
    uint256 public totalBTCDeposited;
    uint256 public totalRewards;
    uint256 public rewardPerShare;
    uint256 public currentEpoch;

    mapping(address => uint256) public userShares;
    mapping(uint256 => Epoch) public epochs;
    mapping(address => bool) public allowedMinters;
    mapping(address => mapping(uint256 => bool)) public rewardsClaimed;

    struct Epoch {
        uint256 totalRewards;
        uint256 rewardPerShare;
    }

    event Deposited(address indexed user, uint256 btcAmount, uint256 sharesIssued);
    event Redeemed(address indexed user, uint256 btcAmount, uint256 sharesBurned);
    event RewardsDistributed(uint256 totalRewards, uint256 rewardPerShare);
    event SlashRecorded(uint256 indexed epoch, uint256 slashAmount, uint256 newBacking);
    event RewardsClaimed(address indexed user, uint256 rewardAmount);
    event MinterUpdated(address indexed minter, bool status);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    modifier onlyMinter() {
        require(allowedMinters[msg.sender], "Not authorized to mint");
        _;
    }

    // Add an authorized minter (operator)
    function setMinter(address _minter, bool _status) external onlyOwner {
        allowedMinters[_minter] = _status;
        emit MinterUpdated(_minter, _status);
    }

    // Deposit BTC and mint shares based on existing supply
    function depositBTC(uint256 amount) external onlyMinter {
        require(amount > 0, "Deposit must be greater than zero");

        if (totalBTCDeposited > 0) {
            uint256 pendingRewards = (amount * epochs[currentEpoch].rewardPerShare) / 1e18;
            epochs[currentEpoch].totalRewards += pendingRewards;
        }

        uint256 sharesToMint = (totalSupply() == 0) ? amount : (amount * totalSupply()) / totalBTCDeposited;
        totalBTCDeposited += amount;
        _mint(msg.sender, sharesToMint);

        userShares[msg.sender] += sharesToMint;
        emit Deposited(msg.sender, amount, sharesToMint);
    }

    // Redeem BTC by burning shares based on dynamic rate
    function redeemBTC(uint256 shares) external {
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");

        uint256 btcAmount = (shares * totalBTCDeposited) / totalSupply();
        _burn(msg.sender, shares);

        totalBTCDeposited -= btcAmount;
        userShares[msg.sender] -= shares;

        emit Redeemed(msg.sender, btcAmount, shares);
    }

    // Add rewards and distribute them per epoch
    function startNewEpoch(uint256 rewardAmount) external onlyOwner {
        require(rewardAmount > 0, "Reward must be greater than zero");

        if (totalBTCDeposited > 0) {
            epochs[currentEpoch].rewardPerShare = (rewardAmount * 1e18) / totalBTCDeposited;
        }

        epochs[currentEpoch].totalRewards = rewardAmount;
        totalRewards += rewardAmount;
        currentEpoch++;

        emit RewardsDistributed(totalRewards, epochs[currentEpoch - 1].rewardPerShare);
    }

    // Claim rewards for the current epoch
    function claimRewards() external {
        require(!rewardsClaimed[msg.sender][currentEpoch - 1], "Rewards already claimed for this epoch");

        uint256 rewards = (balanceOf(msg.sender) * epochs[currentEpoch - 1].rewardPerShare) / 1e18;
        require(rewards > 0, "No rewards available");

        rewardsClaimed[msg.sender][currentEpoch - 1] = true;
        totalRewards -= rewards;

        (bool success, ) = msg.sender.call{value: rewards}("");
        require(success, "Transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    // Handle slashing events by reducing BTC reserves and adjusting shares
    function applySlashing(uint256 slashAmount) external onlyOwner {
        require(slashAmount <= totalBTCDeposited, "Cannot slash more than deposited BTC");

        uint256 newBacking = totalBTCDeposited - slashAmount;
        uint256 rebaseFactor = (newBacking * 1e18) / totalBTCDeposited;
        totalBTCDeposited = newBacking;

        _burn(address(this), totalSupply() - ((totalSupply() * rebaseFactor) / 1e18));

        emit SlashRecorded(currentEpoch, slashAmount, newBacking);
    }

    // Calculate dynamic redemption rate
    function getRedemptionRate() public view returns (uint256) {
        if (totalBTCDeposited == 0) return 0;
        return (totalBTCDeposited * 1e18) / totalSupply();
    }
}
