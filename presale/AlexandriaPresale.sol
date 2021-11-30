// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AlexandriaPresale is Ownable {
    using SafeERC20 for ERC20;
    using Address for address;

    uint constant DAIprecision = 10 ** 18;
    uint public constant PRICE = 2 * DAIprecision / ALXprecision ;

    uint constant ALXprecision = 10 ** 9;
    uint public constant MAX_SOLD = 80000 * ALXprecision;

    uint public constant MIN_PRESALE_PER_ACCOUNT = 1 * ALXprecision;
    uint public constant MAX_PRESALE_PER_ACCOUNT = 400 * ALXprecision;

    address public account;
    ERC20 DAI;

    uint public sold;
    address public ALX;

    // Timestamps for the start of Private sale, second phase and Claim phase
    uint256 depositTimestamp;
    uint256 publicTimestamp;
    uint256 claimTimestamp;

    mapping( address => uint256 ) public invested;
    mapping( address => bool ) public claimed;
    mapping( address => bool ) public nobles;

    constructor(address _alxAddr, uint256 _depositTimestamp, uint256 _claimTimestamp, uint256 _publicTimestamp) {
        ALX = _alxAddr;
        DAI = ERC20(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
        account = 0xC4C4350d5a8a7Bf260B2515F79A802c8418aCE0e;
        depositTimestamp = _depositTimestamp;
        claimTimestamp = _claimTimestamp;
        publicTimestamp = _publicTimestamp;
    }


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /* Adding nobles to the whitelist */
    function _approveBuyer( address newBuyer_ ) internal onlyOwner() returns ( bool ) {
        nobles[newBuyer_] = true;
        return nobles[newBuyer_];
    }

    function approveBuyer( address newBuyer_ ) external onlyOwner() returns ( bool ) {
        return _approveBuyer( newBuyer_ );
    }

    function approveBuyers( address[] calldata newBuyers_ ) external onlyOwner() returns ( uint256 ) {
        for( uint256 iteration_ = 0; newBuyers_.length > iteration_; iteration_++ ) {
            _approveBuyer( newBuyers_[iteration_] );
        }
        return newBuyers_.length;
    }

    function _deapproveBuyer( address newBuyer_ ) internal onlyOwner() returns ( bool ) {
        nobles[newBuyer_] = false;
        return nobles[newBuyer_];
    }

    function deapproveBuyer( address newBuyer_ ) external onlyOwner() returns ( bool ) {
        return _deapproveBuyer(newBuyer_);
    }

    function amountBuyable(address buyer) public view returns (uint256) {
        uint256 max;
        max = MAX_PRESALE_PER_ACCOUNT;
        return max - invested[buyer];
    }

    // Deposit DAI to collect $ALX
    function deposit(uint256 amount) public onlyEOA {
        require(depositTimestamp <= block.timestamp, "deposit not started");
        require(nobles[msg.sender] == true || publicTimestamp <= block.timestamp, "not whitelisted and/or public phase not started");
        require(sold < MAX_SOLD, "sold out");
        require(sold + amount < MAX_SOLD, "not enough remaining");
        require(amount <= amountBuyable(msg.sender), "amount exceeds buyable amount");
        require(amount >= MIN_PRESALE_PER_ACCOUNT, "amount is not sufficient");

        DAI.safeTransferFrom( msg.sender, address(this), amount * PRICE  );
        invested[msg.sender] += amount;
        sold += amount;
    }

    // Claim ALX allocation
    function claimALX() public onlyEOA {
        require(claimTimestamp <= block.timestamp, "cannot claim yet");
        require(!claimed[msg.sender], "already claimed");
        if(invested[msg.sender] > 0) {
            ERC20(ALX).transfer(msg.sender, invested[msg.sender]);
        }
        claimed[msg.sender] = true;
    }

    // Tokens withdrawal
    function withdraw(address _token) public {
        require(msg.sender == account, "!dev");
        uint b = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(account,b);
    }



    function setClaimTimestamp(uint256 _claimTimestamp) external onlyOwner {
        require(block.timestamp < claimTimestamp, "claim already started");
        claimTimestamp = _claimTimestamp;
    }

    function setDepositTimestamp(uint256 _depositTimestamp) external onlyOwner {
        require(block.timestamp < depositTimestamp, "deposit already started");
        depositTimestamp = _depositTimestamp;
    }

    function setPublicTimestamp(uint256 _publicTimestamp) external onlyOwner {
        require(block.timestamp < publicTimestamp, "public already started");
        publicTimestamp = _publicTimestamp;
    }

    function currentTimestamp() view external returns (uint256) {
        return block.timestamp;
    }
}