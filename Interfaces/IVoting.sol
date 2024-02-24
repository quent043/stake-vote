// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoting {

    // Structs
    struct Vote {
        bool voted;
        bool vote;
    }

    // Functions
    function vote(uint256 _surveyId, bool _vote) external;

    function withdraw() external;
}
