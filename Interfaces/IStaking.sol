// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    // Events
    event Staked(address indexed user, address token, uint256 amount);
    event UnStaked(address indexed user, address token, uint256 amount);

    // View functions
    function isTokenAllowed(address _tokenAddress) external view returns (bool);
    function userToTokenToStake(address _user, address _token) external view returns (uint256);

    // Public functions
    function addAllowedToken(address _tokenAddress) external;
    function removeAllowedToken(address _tokenAddress) external;
    function stake(uint256 _amount, address _token) external;
    function unStake(uint256 _amount, address _token) external;
}
