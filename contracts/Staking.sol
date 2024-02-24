// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Staking is UUPSUpgradeable, Initializable, AccessControlUpgradeable {
    IERC20Upgradeable public token;

    mapping(address => bool) public allowedTokenList;
    mapping(address => mapping(address => uint256)) public userToTokenToStake;

    event Staked(address indexed user, address token, uint256 amount);
    event UnStaked(address indexed user, address token, uint256 amount);

    // =========================== Initializers ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice First initializer function
     * @param
     */
    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Increment counter to start profile ids at index 1
        nextProfileId.increment();
    }

    // =========================== View functions ==============================


    function isTokenAllowed(address _tokenAddress) public view returns (bool) {
        return allowedTokenList[_tokenAddress];
    }


    // =========================== Public functions ==============================


    function addAllowedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokenList[_tokenAddress] = true;
    }

    function removeAllowedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokenList[_tokenAddress] = false;
    }

    function stake(uint256 _amount, address _token) external {
        require(allowedTokenList[_token], "Token not allowed");
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        userToTokenToStake[msg.sender][_token] += _amount;

        emit Staked(msg.sender, _token, _amount);
    }

    function unStake(uint256 _amount) external {
        require(userToTokenToStake[msg.sender][_token] >= _amount, "Insufficient staked amount");
        userToTokenToStake[msg.sender][_token] -= _amount;

        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);

        emit UnStaked(msg.sender, _token, _amount);
    }

    // =========================== Private functions ==============================


}
