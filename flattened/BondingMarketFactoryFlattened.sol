// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// src/BondingMarket.sol

contract BondingMarket is Ownable {
    struct Option {
        uint256 totalBets;
        mapping(address => uint256) bets;
        mapping(address => uint256) betCosts; // New mapping to track bet costs
    }

    uint256 public bettingEndTime;
    uint256 public resultDeclareTime;
    uint256 public totalPool;
    bool public eventEnded;
    uint256 public winningOption;
    string[] public optionNames;
    mapping(uint256 => Option) public options;
    address public creator;

    event BetPlaced(
        address indexed bettor,
        uint256 indexed option,
        uint256 amount
    );
    event ResultDeclared(uint256 indexed winningOption);
    event RewardClaimed(address indexed user, uint256 amount);
    event OwnerWithdrawn(uint256 amount);

    constructor(
        uint256 _bettingEndTime,
        string[] memory _optionNames,
        address _owner
    ) Ownable(_owner) {
        require(
            _optionNames.length > 0,
            "At least one option must be provided"
        );

        bettingEndTime = _bettingEndTime;
        eventEnded = false;
        creator = _owner;

        for (uint256 i = 0; i < _optionNames.length; i++) {
            optionNames.push(_optionNames[i]);
            options[i].totalBets = 0;
        }
    }

    modifier beforeBettingEnd() {
        require(block.timestamp < bettingEndTime, "Betting period has ended");
        _;
    }

    modifier afterBettingEnd() {
        require(
            block.timestamp >= bettingEndTime,
            "Betting period has not ended yet"
        );
        _;
    }

    modifier onlyCreatorOrOwner() {
        require(
            msg.sender == creator || msg.sender == owner(),
            "Only the creator or owner can call this function"
        );
        _;
    }

    function calculateBetCost(uint256 option) public view returns (uint256) {
        // Example linear bonding curve: price = 0.003 ether + 0.0001 ether * totalBets
        // You can modify this formula as needed
        uint256 basePrice = 0.003 ether;
        uint256 additionalPrice = 0.003 ether * options[option].totalBets;
        return basePrice + additionalPrice;
    }

    function placeBet(uint256 option) external payable beforeBettingEnd {
        require(option < optionNames.length, "Invalid option");

        uint256 betCost = calculateBetCost(option);
        require(msg.value >= betCost, "Insufficient bet amount");
        require(
            msg.value % betCost == 0,
            "Bet amount must be in increments of the calculated bet cost"
        );

        Option storage o = options[option];
        o.bets[msg.sender] += msg.value;
        o.totalBets += msg.value;
        o.betCosts[msg.sender] = betCost; // Track the bet cost
        totalPool += msg.value;

        emit BetPlaced(msg.sender, option, msg.value);
    }

    function declareResult(
        uint256 _winningOption
    ) external onlyCreatorOrOwner afterBettingEnd {
        require(_winningOption < optionNames.length, "Invalid option");
        winningOption = _winningOption;
        eventEnded = true;
        emit ResultDeclared(_winningOption);
    }

    function claimReward() external afterBettingEnd {
        require(eventEnded, "Event has not ended yet");
        Option storage o = options[winningOption];
        uint256 userBet = o.bets[msg.sender];
        require(userBet > 0, "No reward to claim");

        uint256 userBetCost = o.betCosts[msg.sender];
        uint256 reward = (userBet * totalPool) / (o.totalBets * userBetCost);
        o.bets[msg.sender] = 0;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Measures to be taken if users are unable to withdraw
    function withdrawOwner() external onlyOwner {
        require(
            block.timestamp >= bettingEndTime + 21 days,
            "Withdrawal period has not started yet"
        );
        uint256 ownerAmount = address(this).balance;
        payable(owner()).transfer(ownerAmount);

        emit OwnerWithdrawn(ownerAmount);
    }

    function canClaimReward(address user) external view returns (bool) {
        if (!eventEnded) {
            return false;
        }

        Option storage o = options[winningOption];
        uint256 userBet = o.bets[user];
        return userBet > 0;
    }

    function getUserBet(address user) external view returns (uint256[] memory) {
        uint256[] memory bets = new uint256[](optionNames.length);
        for (uint256 i = 0; i < optionNames.length; i++) {
            bets[i] = options[i].bets[user];
        }
        return bets;
    }

    function getAllInfo()
        external
        view
        returns (
            uint256 _bettingEndTime,
            string[] memory _optionNames,
            uint256[] memory _totalBets
        )
    {
        _bettingEndTime = bettingEndTime;
        _optionNames = optionNames;

        _totalBets = new uint256[](optionNames.length);

        for (uint256 i = 0; i < optionNames.length; i++) {
            _totalBets[i] = options[i].totalBets;
        }
    }
}

// src/BondingMarketFactory.sol

contract BondingMarketFactory {
    BondingMarket[] public markets;

    event MarketCreated(address marketAddress);

    function createMarket(
        uint256 _bettingEndTime,
        string[] memory _optionNames
    ) public {
        BondingMarket market = new BondingMarket(
            _bettingEndTime,
            _optionNames,
            msg.sender
        );
        markets.push(market);
        emit MarketCreated(address(market));
    }

    function getMarkets() public view returns (BondingMarket[] memory) {
        return markets;
    }
}
