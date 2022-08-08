// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

//deploy, transfer, update payment -> gas optimize each

    /**
 * uint256 is 32 bytes
uint128 is 16 bytes
uint64 is 8 bytes
address (and address payable) is 20 bytes
bool is 1 byte
string is usually one byte per character
 */

//admin removed, nvr referaned after being passed into contract
//enum, event placement, change eerythingto emit with errors rather than modifiers
//move functions infoked often up

// [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2]
contract GasContract is AccessControl {
    constructor(address[5] memory _admins, uint256 _totalSupply) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit supplyChanged(msg.sender, _totalSupply);
        administrators = _admins;

        for (uint256 i = 0; i < _admins.length; i++) {
            require(_admins[i] != address(0), "Error-Admin-1");
            grantRole(ADMIN, _admins[i]);
            emit supplyChanged(_admins[i], 0);
        }
    }

    uint256 immutable public totalSupply; // cannot be updated
    
    address[5] public administrators;

    uint256 public constant tradeFlag = 1;
    uint256 public constant basicFlag = 0;
    uint256 public constant dividendFlag = 1;
    uint256 public constant tradePercent = 12;
    uint256 public constant tradeMode = 0;

    uint256 public paymentCounter = 0;

    bool wasLastOdd = true;

    mapping(address => mapping(uint256 => Payment)) public payments;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) public isOddWhitelistUser;
    mapping(address => ImportantStruct) public whiteListStruct;

    bytes32 constant ADMIN = keccak256("Admin");

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType defaultPayment = PaymentType.Unknown;

    struct Payment {
        uint256 paymentID;
        uint256 amount;
        address recipient;
        address admin; // administrators address
        bool adminUpdated;
        string recipientName; // max 8 characters
        PaymentType paymentType;
    }

    struct ImportantStruct {
        uint256 bigValue;
        uint32 valueA; // max 3 digits - anything under 32bits require more gas to convert
        uint32 valueB; // max 3 digits
    }


    error NotWhiteListed(address);


    function _checkIfWhiteListed() internal view {
        if (whitelist[msg.sender] > 0 && whitelist[msg.sender] < 4) {
            revert NotWhiteListed(msg.sender);
        }
    }

    event AddedToWhitelist(address indexed userAddress, uint256 tier);
    event supplyChanged(address indexed indexed, uint256 indexed);
    event Transfer(address indexed recipient, uint256 indexed amount);
    event PaymentUpdated(
        address indexed admin,
        uint256 indexed ID,
        uint256 indexed amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    /***
    function getPaymentHistory() external view returns (History[] memory) {
        return paymentHistory;
    }
     */

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function getTradingMode() public pure returns (bool) {
        if (tradeFlag == 1 || dividendFlag == 1) {
            return true;
        }
        return false;
    }

    function getPayments(address _user)
        external
        view
        returns (Payment[] memory )
    {
        require(_user != address(0), "EGP");
        //reconsruct into payment arr
        Payment[] memory _payments = new Payment[](paymentCounter);
        for(uint i; i < paymentCounter; i++){
           _payments[i] = payments[_user][i+1];
        }
        return _payments;
    }

    //"Gas Contract - getPayments function - User must have a valid non zero address"
    //"Gas Contract - Transfer function - Sender has insufficient Balance"
    //"Gas Contract - Transfer function -  The recipient name is too long, there is a max length of 8 characters"
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        require(balances[msg.sender] >= _amount, "ETG");
        require(bytes(_name).length < 9, "ETN");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);
        payments[msg.sender][paymentCounter] = Payment({
            admin: address(0),
            adminUpdated: false,
            paymentType: PaymentType.BasicPayment,
            recipient: _recipient,
            amount: _amount,
            recipientName: _name,
            paymentID: ++paymentCounter
        });

        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyRole(ADMIN) {
        require(_ID > 0, "EUID"); //"Gas Contract - Update Payment function - ID must be greater than 0"
        require(_amount > 0, "EUA"); //"Gas Contract - Update Payment function - Amount must be greater than 0"
        Payment memory _payment = payments[_user][_ID];

        _payment.adminUpdated = true;
        _payment.admin = msg.sender;
        _payment.paymentType = _type;
        _payment.amount = _amount;

        payments[_user][_ID] = _payment; //copying from mem to storage
        //addHistory function removed because history is saved to logs
        emit PaymentUpdated(
            msg.sender,
            _ID,
            _amount,
            _payment.recipientName
        );
    }

            //"Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
    function addToWhitelist(address _userAddrs, uint256 _tier) external onlyRole(ADMIN) {
        require(
            _tier < 3 && _tier > 0,
        "EAWLT"
        );
        //allowable numbers for tier according to previous logic are 1& 2
        whitelist[_userAddrs] = _tier;
            wasLastOdd = !wasLastOdd;
            isOddWhitelistUser[_userAddrs] = wasLastOdd;
        emit AddedToWhitelist(_userAddrs, _tier);
    }
            //"Gas Contract - whiteTransfers function - Sender has insufficient Balance"
            //"Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
    function whiteTransfer(
        address _recipient,
        uint256 _amount,
        ImportantStruct memory _struct
    ) public {
        _checkIfWhiteListed();
        uint msgSenderBalance = balances[msg.sender] ;
        uint recipientBalance = balances[_recipient] ;
        uint whitelistBalance = whitelist[msg.sender];
        require(
            msgSenderBalance  >= _amount,
            "EWTB"
        );
        require(
            _amount > 3,
            "EWTA"
        );
        msgSenderBalance -= _amount;
        msgSenderBalance += whitelistBalance;
        recipientBalance += _amount;
        recipientBalance -= whitelistBalance;
        //balances[msg.sender] -= _amount;
        //balances[_recipient] += _amount;
        //balances[msg.sender] += whitelist[msg.sender];
        //balances[_recipient] -= whitelist[msg.sender];
        balances[msg.sender] = msgSenderBalance;
        balances[_recipient] = recipientBalance;
        whiteListStruct[msg.sender] = _struct;
        emit WhiteListTransfer(_recipient);
    }
}
