// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DeFi1.sol";
import "../src/Token.sol";

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
    uint256 blockRewardRate = 1000;

    function setUp() public {
        defi = new DeFi1(initialAmount, blockRewardRate);
        token = Token(defi.token.address);
        alice = new User();
        bob = new User();
        chloe = new User();
    }

///functions prefixed with testFail should revert, or it will fail
    function testInitialBalance() public view {
       assert(initialAmount == defi.initialAmount());
    }
    function testInitRewardRate() public view {
       assert(blockRewardRate == defi.rewardRate());
    }
    function testFailInitialBalance() public view {
       assert(initialAmount + 1 == defi.initialAmount());
    }
    function testFailInitRewardRate() public view {
       assert(blockRewardRate +1 == defi.rewardRate());
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

    function testCanClaim() public {
        defi.addInvestor(address(alice));
        defi.addInvestor(address(bob));
        vm.prank(address(alice));//alice = msg.sender
        vm.roll(1);//blocknumer setto 1
        defi.claimTokens();
    }
    function testCannotClaim() public {
        vm.expectRevert(bytes("notInvestor"));
        defi.addInvestor(address(alice));
        defi.addInvestor(address(bob));
        vm.prank(address(chloe));//alice = msg.sender
        vm.roll(1);//blocknumer setto 1
        defi.claimTokens();
    }


    function testCorrectPayoutAmount() public {

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
