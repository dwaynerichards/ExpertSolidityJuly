//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "./Token.sol";

contract DeFi1 {
    uint256 initialAmount = 0;
    uint256 numInvestors;
    mapping(address => bool) investors;
    uint256 rewardRate;
    uint256 blockNumber;
    Token public token;

    constructor(uint256 _initialAmount, uint256 _rewardRate) {
        initialAmount = initialAmount;
        token = new Token(_initialAmount);
        blockNumber = block.number;
        rewardRate = _rewardRate;
    }

    function claimTokens() public {
        require(investors[msg.sender], "notInvestor");
        token.transfer(msg.sender, _calculatePayout());
    }

    /**
@dev function reduces blockNum storageVar every 1000 blocks
@return uint256 payout to investors
 */
    function _calculatePayout() internal returns (uint256) {
        if (block.number >= block.number + 1000) {
            blockNumber = block.number;
            rewardRate - 100;
        }
        uint256 blockReward = block.number % rewardRate;
        return (initialAmount / numInvestors) * blockReward;
    }

    function addInvestor(address _investor) public {
        require(!investors[_investor], "alreadyInvestor");
        investors[_investor] = true;
        numInvestors++;
    }
}
