//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Token.sol";
import "forge-std/console2.sol";

contract DeFi1 {
    uint256 public immutable initialAmount;
    uint256 public numInvestors;
    uint256 public blockReward;
    uint256 public blockNumber;
    mapping(address => bool) public investors;
    Token public immutable token;

    constructor(uint256 _initialAmount, uint256 _blockReward) {
        initialAmount = _initialAmount;
        token = new Token(_initialAmount);
        blockNumber = block.number;
        blockReward = _blockReward;
    }

    function claimTokens() public {
        require(investors[msg.sender], "notInvestor");
        require(block.number > blockNumber, "tooSoon");
        token.transfer(msg.sender, _calculatePayout());
    }

    /**
@dev function updates blockNumber and calculates payout
@return uint256 payout to investors based on number of investors and reward rate
 */
    function _calculatePayout() internal returns (uint256) {
        uint256 blockDiff = block.number - blockNumber;
        console2.log("BlockNumber=====>");
        console2.logUint(block.number);
        uint256 _blockReward = _calculateReward(blockDiff);
        blockNumber = block.number;
        blockReward = _blockReward;
        return (initialAmount / numInvestors) * _blockReward;
    }

    function _calculateReward(uint256 _diff) internal view returns (uint256) {
        return ((block.number / 1000) - _diff);
    }

    function addInvestor(address _investor) public {
        require(!investors[_investor], "alreadyInvestor");
        investors[_investor] = true;
        numInvestors++;
    }
}
