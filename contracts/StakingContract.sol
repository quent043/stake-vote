// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Staking Contract
 * @notice This contract manages the staking of ERC20 tokens.
 * @author Quentin D.C.
 * @dev Implements UUPS (Universal Upgradeable Proxy Standard) for upgradability.
 */
contract StakingContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {
    // =========================== Variables & Declarations ==============================

    /**
     * @notice Mapping from token address to their status
     */
    mapping(address => bool) public allowedTokenList;

    /**
     * @notice Mapping from user address to token address to staked amount
     */
    mapping(address => mapping(address => uint256)) public userToTokenToStake;


    // =========================== Events ==============================

    /**
     * @notice Emitted when a user stakes a token
     */
    event Staked(address indexed user, address token, uint256 amount);

    /**
     * @notice Emitted when a user unstakes a token
     */
    event UnStaked(address indexed user, address token, uint256 amount);

    /**
     * @notice Emitted when a token is added to the allowed list
     */
    event TokenAdded(address indexed token);

    /**
     * @notice Emitted when a token is removed from the allowed list
     */
    event TokenRemoved(address indexed token);


    // =========================== Initializers ==============================

    /**
     * @notice Constructor replacement for upgradeable contracts
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     */
    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Checks if a token is allowed for staking
     * @param _tokenAddress The address of the token
     * @return bool Returns true if the token is allowed, false otherwise
     */
    function isTokenAllowed(address _tokenAddress) public view returns (bool) {
        return allowedTokenList[_tokenAddress];
    }

    /**
     * @notice Gets the staked amount of a specific token for a user
     * @param user The address of the user
     * @param token The address of the token
     * @return uint256 The staked amount
     */
    function getStakedAmount(address user, address token) public view returns (uint256) {
        return userToTokenToStake[user][token];
    }

    // =========================== Public functions ==============================

    /**
     * @notice Updates the list of allowed tokens for staking
     * @param _tokenAddress The address of the token
     * @param _isAllowed The status to set for this token
     */
    function updateAllowedTokenList(address _tokenAddress, bool _isAllowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddress != address(0), "Token address cannot be 0x0");
        allowedTokenList[_tokenAddress] = _isAllowed;

        emit TokenAdded(_tokenAddress);
    }

    /**
     * @notice Removes a token from the list of allowed tokens
     * @param _tokenAddress The address of the token
     */
    function removeAllowedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokenList[_tokenAddress] = false;

        emit TokenRemoved(_tokenAddress);
    }

    /**
     * @notice Allows a user to stake a specific amount of a token
     * @param _amount The amount of the token to stake
     * @param _token The address of the token
     */
    function stake(uint256 _amount, address _token) external {
        require(allowedTokenList[_token], "Token not allowed");

        IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _amount);

        userToTokenToStake[msg.sender][_token] += _amount;

        emit Staked(msg.sender, _token, _amount);
    }

    /**
     * @notice Allows a user to unstake a specific amount of a token
     * @param _amount The amount of the token to unstake
     * @param _token The address of the token
     */
    function unStake(uint256 _amount, address _token) external {
        require(userToTokenToStake[msg.sender][_token] >= _amount, "Insufficient staked amount");
        userToTokenToStake[msg.sender][_token] -= _amount;

        IERC20Upgradeable(_token).transfer(msg.sender, _amount);

        emit UnStaked(msg.sender, _token, _amount);
    }

    /**
     * @notice Allow receiving of ETH
     */
    receive() external payable {}

    /**
     * @notice Allows withdrawal of contract balance by the admin
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =========================== Internal functions ==============================

    /**
     * @notice Function that reverts when `_msgSender()` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @param newImplementation Address of the new contract implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}

}
