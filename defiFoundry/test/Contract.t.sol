// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DeFi1.sol";
import "../src/Token.sol";
import "forge-std/console2.sol";

contract User {
    receive() external payable {}
}

contract ContractTest is Test {
    DeFi1 defi;
    Token token;
    User internal alice;
    User internal bob;
    User internal chloe;
    uint256 initialAmount = 1000;
    uint256 blockReward= 1000;

    function setUp() public {
_setCurrentBlock();
        defi = new DeFi1(initialAmount, blockReward);
        token = Token(defi.token.address);
        alice = new User();
        bob = new User();
        chloe = new User();
    }
    function _setCurrentBlock() internal {
        string memory MAINNET =  vm.rpcUrl("mainnet");
        vm.createSelectFork(MAINNET);
        assertTrue(block.number > 15000000);
    }

    function canReadEndpoint() external {
        string memory url = vm.rpcUrl("mainnet");
        assertEq(url, "https://eth-mainnet.g.alchemy.com/v2/Igv4mP6opRr8JkHDqJs7IaHCkbdoFL9O");
    }

///functions prefixed with testFail should revert, or it will fail
    function testInitialBalance() public view {
       assert(initialAmount == defi.initialAmount());
    }
    function testInitRewardRate() public view {
       assert(blockReward== defi.blockReward());
    }
    function testFailInitialBalance() public view {
       assert(initialAmount + 1 == defi.initialAmount());
    }
    function testFailInitRewardRate() public view {
       assert(blockReward+1 == defi.blockReward());
    }
    function testInitNumInvestors() public view {
        assert(defi.numInvestors() == 0);
    }
    function testFailInitNumInvestors() public view {
        assert(defi.numInvestors() == 1);
    }

    function testAddInvestor() public {
        defi.addInvestor(address(alice));
        assert(defi.investors(address(alice)) == true);
        assert(defi.numInvestors() == 1);
    }
    function tesFailAddInvestor() public {
        defi.addInvestor(address(alice));
        assert(defi.investors(address(alice)) == false);
        assert(defi.numInvestors() == 0);
    }
/**
 When testing make sure you know
how would you advance blocks
how would you make sure every block will work
how would you make sure the contract works with different starting values such
as
block reward,
numbers of investors
initial number of tokens Try to find all the bugs / security problems*/
    function testCanClaim() public {
        console2.log("in test");
        ///create and select fork, returns a fork Id
        ///verify ID/ blocknumner
        defi.addInvestor(address(alice));
        defi.addInvestor(address(bob));
        _advanceBlocks(1);
        vm.prank(address(alice));//alice = msg.sender
        defi.claimTokens();
    }
    function testCannotClaim() public {
        defi.addInvestor(address(alice));
        defi.addInvestor(address(bob));
        _advanceBlocks(1);
        vm.expectRevert(bytes("notInvestor"));
        vm.prank(address(chloe));//alice = msg.sender
        defi.claimTokens();
    }
    
    function _advanceBlocks(uint num) internal{
        vm.roll(defi.blockNumber() + num);
    }


    function testCorrectPayoutAmount() public {
        defi.addInvestor(address(alice));
        _advanceBlocks(1000);

    }

    function testAddingManyInvestors() public {
        defi.addInvestor(address(alice));
        assert(defi.investors(address(alice)) == true);
        assert(defi.numInvestors() == 1);
        defi.addInvestor(address(bob));
        assert(defi.investors(address(bob)) == true);
        assert(defi.numInvestors() == 2);
        defi.addInvestor(address(chloe));
        assert(defi.investors(address(chloe)) == true);
        assert(defi.numInvestors() == 3);

    }

    function testAddingManyInvestorsAndClaiming() public {
        defi.addInvestor(address(alice));
        assert(defi.investors(address(alice)) == true);
        assert(defi.numInvestors() == 1);
        defi.addInvestor(address(bob));
        assert(defi.investors(address(bob)) == true);
        assert(defi.numInvestors() == 2);
        assert(defi.investors(address(chloe)) == true);
        assert(defi.numInvestors() == 3);
    }

}
