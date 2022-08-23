//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Token.sol";
import "forge-std/console2.sol";

contract DeFi1 {
    uint256 public immutable initialAmount;
    uint256 public numInvestors;
    uint256 public blockReward;
    uint256 public blockNumber;
    mapping(address => blockDetails) public investors;
    Token public token;
    struct blockDetails {
        bool isInvestor;
        uint256 blockPaid;
    }

    constructor(uint256 _initialAmount, uint256 _blockReward) {
        blockNumber = block.number;
        initialAmount = _initialAmount;
        blockReward = _blockReward;
        ///initalAmount updated in Token contract to 10**18
        token = new Token(_initialAmount);
    }

    function claimTokens() public returns (uint256 payout) {
        require(_isInvestor(msg.sender), "notInvestor");
        require(block.number > _blockPaid(msg.sender), "tooSoon");
        payout = _calculatePayout();
        token.transfer(msg.sender, payout);
    }

    /**
@dev function updates blockNumber and calculates payout
@return uint256 payout to investors based on number of investors and reward rate
 */
    function _calculatePayout() internal returns (uint256) {
        uint256 blockDiff = block.number - blockNumber;
        investors[msg.sender].blockPaid = blockNumber = block.number;
        blockReward = _calculateReward(blockDiff);
        //console2.log("init amount, numInvest", initialAmount, numInvestors);
        //console2.log("payout", (blockReward));
        return blockReward;
    }

    function _calculateReward(uint256 _diff) internal view returns (uint256) {
        console2.log(
            "reward",
            (initialAmount * (block.number / 1000)) / numInvestors - _diff
        );
        return ((initialAmount * (block.number / 1000)) / numInvestors) - _diff;
    }

    function addInvestor(address _investor) public {
        require(!_isInvestor(_investor), "alreadyInvestor");
        require(numInvestors < initialAmount, "maxInvestors");
        investors[_investor].isInvestor = true;
        numInvestors++;
    }

    function isInvestor(address _investor) external view returns (bool) {
        return _isInvestor(_investor);
    }

    function _isInvestor(address _investor) internal view returns (bool) {
        return investors[_investor].isInvestor;
    }

    function _blockPaid(address _investor) internal view returns (uint256) {
        return investors[_investor].blockPaid;
    }
}
