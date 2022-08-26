// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract DogCoin is ERC20, PullPayment {
    mapping(address => bool) players;
    address[] winners;
    uint256[] shares;
    uint256 playerSlots;

    event startPayout();
    uint256 constant pricePerEth = 1000;

    constructor() ERC20("DogCoin", "Dog") {
        _mint(address(this), 1000000);
    }

    enum State {
        joinGame,
        pickWinner,
        payout
    }
    State state = State.joinGame;

    function _isPlayer(address _player) internal view returns (bool) {
        return players[_player];
    }

    modifier canAdd(address _player) {
        require(_canAdd(_player), "cantAdd");
        _;
    }

    function _canAdd(address _player) internal view returns (bool) {
        require(msg.value >= 1 ether, "insufficentEth");
        require(state == State.joinGame, "maxPlayers");
        require(!_isPlayer(_player), "alreadyPlayer");
        return true;
    }

    function addPlayer(address _player) external payable canAdd(_player) {
        players[_player] = true;
        if (playerSlots > 199) {
            state = State.pickWinner;
            playerSlots = 99;
        }
    }

    function addWinner(address _winner) external {
        require(state == State.pickWinner, "maxPlayers");
        winners[playerSlots--] = _winner;
        shares[playerSlots] = 1;

        if (playerSlots == 0) {
            state = State.payout;
        }
    }

    ///OZ PullPayments/Escrow updated to not include pulling payments from erc20 tokens
    ///Differing Function signatures of asyncTransfer allows same name of functions
    /// Copy of updated pullPayments/Escrow exists in directory
    function _escrowWinnings(address _winner) internal {
        _asyncTransfer(this, _winner, pricePerEth);
        _asyncTransfer(_winner, _etherToWei(1));
    }

    function _etherToWei(uint256 _eth) internal pure returns (uint256) {
        return _eth * (10**18);
    }

    function payout(address _winner) external {
        require(state == State.payout, "payoutToSoon");
        _withdrawEscro(_winner);
    }

    function _withdrawEscro(address _winner) internal {
        withdrawPayments((payable(_winner)));
        withdrawPayments(this, payable(_winner));
    }
}
