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
    uint256 blockReward = 1000;

    function setUp() public {
        _forkMainnet(_setEnvVar());
        defi = new DeFi1(initialAmount, blockReward);
        token = Token(address(defi.token()));
        alice = new User();
        bob = new User();
        chloe = new User();
    }

    ///functions prefixed with testFail should revert, or it will fail
    function testInitialBalance() public view {
        assert(token.totalSupply() == defi.initialAmount() * (10**18));
    }

    function testInitRewardRate() public view {
        assert(blockReward == defi.blockReward());
    }

    function testFailInitialBalance() public view {
        assert(initialAmount + 1 == defi.initialAmount());
    }

    function testFailInitRewardRate() public view {
        assert(blockReward + 1 == defi.blockReward());
    }

    function testInitNumInvestors() public view {
        assert(defi.numInvestors() == 0);
    }

    function testFailInitNumInvestors() public view {
        assert(defi.numInvestors() == 1);
    }

    function testAddInvestor() public {
        defi.addInvestor(address(alice));
        assertTrue(defi.isInvestor(address(alice)));
        assert(defi.numInvestors() == 1);
    }

    function tesFailAddInvestor() public {
        defi.addInvestor(address(alice));
        assertFalse(defi.isInvestor(address(alice)));
        assert(defi.numInvestors() == 0);
    }

    /**
how would you make sure every block will work
how would you make sure the contract works with different starting values such
as
block reward,
numbers of investors
initial number of tokens Try to find all the bugs / security problems*/
    /**
     @notice expectrevert ignores all calls to other cheatcodes before reverting call
     We must call prank directly before the reverting call
     */
    function testCanClaim() public {
        defi.addInvestor(address(alice));
        _advanceBlocks(1);
        _canClaim(alice);
    }

    function _canClaim(User _investor) internal {
        uint256 defiBalance = token.balances(address(defi));
        uint256 investorBalance = token.balances(address(_investor));

        vm.prank(address(_investor)); //alice = msg.sender
        uint256 tokensClaimed = defi.claimTokens();
        uint256 newSupply = defiBalance - tokensClaimed;
        assertEq(newSupply, token.balanceOf(address(defi)));
        assertEq(
            (tokensClaimed + investorBalance),
            token.balanceOf(address(_investor))
        );
    }

    function testCannotClaim() public {
        defi.addInvestor(address(alice));
        _advanceBlocks(1);
        vm.expectRevert(bytes("notInvestor"));
        vm.prank(address(chloe)); //chloe = msg.sender
        defi.claimTokens();
    }

    /// how would you advance blocks
    function _advanceBlocks(uint256 num) internal {
        uint256 futureBlockNum = block.number + num;
        vm.roll(futureBlockNum);
        assertEq(block.number, futureBlockNum);
    }

    function testCorrectPayoutAmount() public {
        bool correctAmount = _tstCorrectPayout(alice, 10);
        assertTrue(correctAmount);
        correctAmount = _tstCorrectPayout(chloe, 100);
        assertTrue(correctAmount);
        correctAmount = _tstCorrectPayout(bob, 1000);
        assertTrue(correctAmount);
    }

    function _tstCorrectPayout(User _investor, uint256 _blocksAdvance)
        internal
        returns (bool)
    {
        defi.addInvestor(address(_investor));
        _advanceBlocks(_blocksAdvance);
        vm.prank(address(_investor));
        uint256 tokensClaimed = defi.claimTokens();
        uint256 tokensCalculated = _calculatePayout(_blocksAdvance);
        return (tokensClaimed == tokensCalculated);
    }

    function _calculatePayout(uint256 diff) internal view returns (uint256) {
        return
            ((defi.initialAmount() * (block.number / 1000)) /
                defi.numInvestors()) - diff;
    }

    function testAddingManyInvestors() public {
        _addManyInvestors();
    }

    function _addManyInvestors() internal {
        defi.addInvestor(address(alice));
        assertTrue(defi.isInvestor(address(alice)));
        assert(defi.numInvestors() == 1);
        defi.addInvestor(address(bob));
        assertTrue(defi.isInvestor(address(bob)));
        assert(defi.numInvestors() == 2);
        defi.addInvestor(address(chloe));
        assertTrue(defi.isInvestor(address(chloe)));
        assert(defi.numInvestors() == 3);
    }

    function testAddingManyInvestorsAndClaiming() public {
        _addManyInvestors();
        _advanceBlocks(10);
        _canClaim(alice);
        _canClaim(bob);
        _canClaim(chloe);
        _advanceBlocks(100);
        _canClaim(alice);
        _canClaim(bob);
        _canClaim(chloe);
        _advanceBlocks(1000);
        _canClaim(alice);
        _canClaim(bob);
        _canClaim(chloe);
    }

    function testCanReadEndpoint() external {
        string memory url = vm.rpcUrl("mainnet");
        assertEq(
            url,
            "https://eth-mainnet.g.alchemy.com/v2/Igv4mP6opRr8JkHDqJs7IaHCkbdoFL9O"
        );
    }

    function _setEnvVar() internal returns (string memory) {
        vm.setEnv(
            "ALCHEMY_ENDPOINT_MAINNET",
            "https://eth-mainnet.g.alchemy.com/v2/Igv4mP6opRr8JkHDqJs7IaHCkbdoFL9O"
        );
        string memory mainnetEnv = vm.envString("ALCHEMY_ENDPOINT_MAINNET");
        assertEq(
            "https://eth-mainnet.g.alchemy.com/v2/Igv4mP6opRr8JkHDqJs7IaHCkbdoFL9O",
            mainnetEnv
        );
        return mainnetEnv;
    }

    /**
      @dev takes a urlEndpoint and forks mainnet, sets blocknumber to current blocknumber 
      @param url: endpoint used to read blockchain data  
      */
    function _forkMainnet(string memory url) internal {
        vm.createSelectFork(url);
        assertTrue(block.number > 15000000);
    }
}
