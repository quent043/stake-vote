// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVoting.sol";

interface ISurvey {

    // Structs
    struct Survey {
        address owner;
        string descriptionUri;
        bool active;
        address tokenAddress;
        uint256 yesCount;
        uint256 noCount;
        uint256 minimumStake;
        uint256 endTimestamp;
        mapping(address => Vote) votes;
    }

    // Events
    event SurveyCreated(uint256 surveyId, address owner, string descriptionUri, address tokenAddress, uint256 minimumStake, uint256 endTimestamp);
    event SurveyCancelled(uint256 surveyId);
    event SurveyCostUpdated(uint256 newCost);

    // Functions
    function getSurvey(uint256 surveyId) external view returns (Survey);

    function hasVoted(uint256 _surveyId, address user) external view returns (bool);

    function updateSurveyCost(uint256 _newCost) external;

    function createSurvey(
        address _tokenAddress,
        string calldata _descriptionUri,
        address _tokenAddress,
        uint256 _minimumStake,
        uint256 _durationInDays
    ) external;

    function cancelSurvey(uint256 _surveyId) external;

    function withdraw() external;
}
