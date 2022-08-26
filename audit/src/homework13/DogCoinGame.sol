// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";

/**
"DogCoinGame is a game where players are added to the contract via the addPlayer function,
 they need to send 1 ETH to play.
Once 200 players have entered, the UI will be notified by the startPayout event,
 and will pick 100 winners which will be added to the winners array, 
 the UI will then call the payout function to pay each of the winners.
The remaining balance will be kept as profit for the developers."

Write out the main points that you would include in an audit.
 */

contract DogCoinGame is ERC20 {
    ///current prize can be immutable and a percentage of
    uint256 public currentPrize;
    uint256 public numberPlayers;
    address payable[] public players;
    address payable[] public winners;

    event startPayout();

    constructor() ERC20("DogCoin", "DOG") {}

    ///All state changine function should have events
    ///Init array to ahve max length of 200- or use iterative mapping- you can run out of gass iterathingthough arr
    ///have users collect funds rather than iterating though array and sending funds
    ///Add accessControl on function to dictate how many pappy can join game
    //prize paid in DogCoin or ether
    ///msgVal needs to be denomicated in ether
    function addPlayer(address payable _player) public payable {
        if (msg.value == 1) {
            players.push(_player);
        }
        numberPlayers++;
        if (numberPlayers > 200) {
            emit startPayout();
        }
    }

    ///function modifiers need to be placed on addwinner- access control
    function addWinner(address payable _winner) public {
        winners.push(_winner);
    }

    ///modifiers for accessControl
    ///balance addPlayer function should balance check
    function payout() public {
        if (address(this).balance == 100) {
            uint256 amountToPay = winners.length / 100;
            payWinners(amountToPay);
        }
    }

    ///should ne internalContract- integrate pull payments
    function payWinners(uint256 _amount) public {
        for (uint256 i = 0; i <= winners.length; i++) {
            winners[i].send(_amount);
        }
    }
    ///create a token to eth conversion rate- send rate to player
}
