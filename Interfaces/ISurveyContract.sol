// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVotingContract.sol";

interface ISurveyContract {

    // Structs
    struct Survey {
        address owner;
        string descriptionUri;
        SurveyStatus status;
        SurveyResult result;
        address tokenAddress;
        uint256 yesCount;
        uint256 noCount;
        uint256 minimumStake;
        uint256 endTimestamp;
    }

    // enums
    enum SurveyStatus {
        Active,
        Finished,
        Cancelled
    }

    enum SurveyResult {
        pending,
        Yes,
        No,
        tie
    }

    // Events
    event SurveyCreated(uint256 surveyId, address owner, string descriptionUri, address tokenAddress, uint256 minimumStake, uint256 endTimestamp);
    event SurveyCancelled(uint256 surveyId);
    event SurveyCostUpdated(uint256 newCost);

    // Functions
    function getSurvey(uint256 surveyId) external view returns (Survey memory);

    function updateSurveyCost(uint256 _newCost) external;

    function createSurvey(
        address _tokenAddress,
        string calldata _descriptionUri,
        uint256 _minimumStake,
        uint256 _durationInDays
    ) external;

    function cancelSurvey(uint256 _surveyId) external;

    function afterVote(uint256 _surveyId, address _voterAddress, bool _vote) external;

    function withdraw() external;
}
