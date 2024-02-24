// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/**TODO: finir les améliorations sur la PartI
* TODO: audit contracts
* TODO: NatSpec
Natspec
Tests
*/

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract StakingContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {
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
     */
    function initialize() public initializer {
        __AccessControl_init();
//        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================


    function isTokenAllowed(address _tokenAddress) public view returns (bool) {
        return allowedTokenList[_tokenAddress];
    }

    //TODO needed?
    function getStakedAmount(address user, address token) public view returns (uint256) {
        return userToTokenToStake[user][token];
    }


    // =========================== Public functions ==============================


    function updateAllowedTokenList(address _tokenAddress, bool _isAllowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokenList[_tokenAddress] = _isAllowed;
    }

    function removeAllowedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokenList[_tokenAddress] = false;
    }

    function stake(uint256 _amount, address _token) external {
        require(allowedTokenList[_token], "Token not allowed");
        IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _amount);

        userToTokenToStake[msg.sender][_token] += _amount;

        emit Staked(msg.sender, _token, _amount);
    }

    function unStake(uint256 _amount, address _token) external {
        require(userToTokenToStake[msg.sender][_token] >= _amount, "Insufficient staked amount");
        userToTokenToStake[msg.sender][_token] -= _amount;

        IERC20Upgradeable(_token).transfer(msg.sender, _amount);

        emit UnStaked(msg.sender, _token, _amount);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =========================== Private functions ==============================
    // =========================== Internal functions ==============================

    /**
     * @notice Function that revert when `_msgSender()` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @param newImplementation address of the new contract implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}


}
