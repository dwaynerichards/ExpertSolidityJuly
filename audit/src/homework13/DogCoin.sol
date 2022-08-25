// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./IpmtSplitter.sol";

contract DogCoin is ERC20 {
    PaymentSplitter pmtSplitter;
    mapping(address => Player) players;

    struct Player {
        uint256 id;
        bool isPlayer;
    }
    address[] winners;
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

    //200 payers, 100 winners
    //at 200 pick 100 winners- init payment splliter
    function _isPlayer(address _player) internal view returns (bool) {
        return players[_player].isPlayer;
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
        players[_player] = Player({id: playerSlots++, isPlayer: true});
        if (playerSlots > 199) {
            state = State.pickWinner;
            playerSlots = 99;
        }
    }

    function addWinner(address _winner) external {
        require(state == State.pickWinner, "maxPlayers");
        winners[playerSlots--] = _winner;
        if (playerSlots == 0) {
            _allowPmts();
        }
    }

    function payout(address _winner) external {
        require(state == State.payout, "payoutToSoon");

        IpmtSplitter(address(pmtSplitter)).release(address(this), _winner);
        //pmtSplitter.release(address(this), _winner);
    }

    function _allowPmts() internal {
        pmtSplitter = new PaymentSplitter(winners, _createShares());
        transfer(pmtSplitter, totalSupply());
        //transfer tokens to payment splitter, then release to person
        state = State.payout;
    }

    function _createShares() internal pure returns (uint256[] memory) {
        uint256[] memory _shares;
        for (uint256 i = 0; i < _shares.length; i++) {
            _shares[i] = 1;
        }
        return _shares;
    }
    //        pmtSplitter = new PaymentSplitter(winners, );
}
