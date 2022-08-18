//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Token.sol";

contract DeFi1 {
    uint256 public immutable initialAmount;
    uint256 public numInvestors;
    uint256 public rewardRate;
    uint256 public blockNumber;
    mapping(address => bool) public investors;
    Token public immutable token;

    constructor(uint256 _initialAmount, uint256 _rewardRate) {
        initialAmount = _initialAmount;
        token = new Token(_initialAmount);
        blockNumber = block.number;
        rewardRate = _rewardRate;
    }

    function claimTokens() public {
        require(investors[msg.sender], "notInvestor");
        require(block.number > blockNumber, "tooSoon");
        token.transfer(msg.sender, _calculatePayout());
    }

    /**
@dev function reduces blockNum storageVar every 1000 blocks
@return uint256 payout to investors
 */
    function _calculatePayout() internal returns (uint256) {
        uint256 blockDiff = block.number - blockNumber;
        if (blockDiff > 1000) {
            (blockNumber, rewardRate) = _calculateRate(blockDiff);
        }
        uint256 blockReward = block.number % rewardRate;
        return (initialAmount / numInvestors) * blockReward;
    }

    function _calculateRate(uint256 _blockDiff)
        internal
        view
        returns (uint256 _blockNum, uint256 _rewardRate)
    {
        uint256 rate = _blockDiff / 1000;
        uint256 rewardDeduction = rate * 100;
        return (block.number, (rewardRate - rewardDeduction));
    }

    function addInvestor(address _investor) public {
        require(!investors[_investor], "alreadyInvestor");
        investors[_investor] = true;
        numInvestors++;
    }
}
