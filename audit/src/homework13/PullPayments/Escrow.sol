// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../Address.sol";
import "../../access/Ownable.sol";
import "../../token/ERC20/utils/SafeERC20.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event TokenDeposited(IERC20 token, address indexed payee, uint256 weiAmount);
    event TokenWithdrawn(IERC20 token, address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;
    mapping(IERC20 => mapping(address => uint256)) private _tokenDeposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    function depositsOf(IERC20 token, address payee) public view returns (uint256) {
        return _tokenDeposits[token][payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    function deposit(
        IERC20 token,
        address payee,
        uint256 amount
    ) public payable virtual onlyOwner {
        _tokenDeposits[token][payee] += amount;
        emit TokenDeposited(token, payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];
        _deposits[payee] = 0;
        payee.sendValue(payment);
        emit Withdrawn(payee, payment);
    }

    function withdraw(IERC20 token, address payable payee) public virtual onlyOwner {
        uint256 payment = _tokenDeposits[token][payee];
        _tokenDeposits[token][payee] = 0;
        SafeERC20.safeTransfer(token, payee, payment);
        emit TokenWithdrawn(token, payee, payment);
    }
}
