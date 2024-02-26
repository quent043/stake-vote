// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingContract {

    // Structs
    struct Vote {
        bool voted;
        bool vote;
    }

    // Events
    event Voted(uint256 indexed surveyId, address indexed voter, bool vote);

    // Functions
    function hasVoted(uint256 _surveyId, address _voter) external view returns (bool);

    function vote(uint256 _surveyId, bool _vote) external;

    function withdraw() external;
}
