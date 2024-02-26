// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingContract {
    // Events
    event Staked(address indexed user, address token, uint256 amount);

    event UnStaked(address indexed user, address token, uint256 amount);

    event TokenAdded(address indexed token);

    event TokenRemoved(address indexed token);

    // View functions
    function isTokenAllowed(address _tokenAddress) external view returns (bool);

    function getStakedAmount(address user, address token) external view returns (uint256);

    // Public functions
    function updateAllowedTokenList(address _tokenAddress, bool _isAllowed) external;

    function removeAllowedToken(address _tokenAddress) external;

    function stake(uint256 _amount, address _token) external;

    function unStake(uint256 _amount, address _token) external;

    function withdraw() external;
}
