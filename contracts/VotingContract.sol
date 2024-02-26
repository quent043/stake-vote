// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../Interfaces/IStakingContract.sol";
import "../Interfaces/ISurveyContract.sol";

/**
 * @title Voting Contract
 * @notice This contract allows users to vote on surveys based on their staked tokens.
 * @author Quentin D.C.
 * @dev This contract utilizes UUPS (Universal Upgradeable Proxy Standard) for upgradability.
 */
contract VotingContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {

    // =========================== Variables & Declarations ==============================

    /**
     * @notice Staking Contract interface
     */
    IStakingContract public stakingContract;

    /**
     * @notice Survey Contract interface
     */
    ISurveyContract public surveyContract;

    /**
     * @notice Structure to store vote details
     */
    struct Vote {
        bool voted; // Indicates if the user has voted
        bool vote;  // The vote itself (true/false)
    }

    // =========================== Mappings ==============================

    /**
     * @notice Mapping from survey ID to voter address to Vote struct
     */
    mapping(uint256 => mapping(address => Vote)) public surveyToVoterToVote;

    // =========================== Events ==============================

    /**
     * @notice Event emitted when a vote is cast
     */
    event Voted(uint256 indexed surveyId, address indexed voter, bool vote);

    // =========================== View functions ==============================

    /**
     * @notice Checks if a user has voted on a survey
     * @param _surveyId The ID of the survey
     * @param _voter The address of the voter
     * @return bool Returns true if the user has voted, false otherwise
     */
    function hasVoted(uint256 _surveyId, address _voter) external view returns (bool) {
        return surveyToVoterToVote[_surveyId][_voter].voted;
    }

    // =========================== Initializers ==============================

    /**
     * @notice Constructor replacement for upgradeable contracts
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with staking and survey contract addresses
     * @param _stakingContractAddress The address of the staking contract
     * @param _surveyContractAddress The address of the survey contract
     */
    function initialize(address _stakingContractAddress, address _surveyContractAddress) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingContract = IStakingContract(_stakingContractAddress);
        surveyContract = ISurveyContract(_surveyContractAddress);
    }

    // =========================== Public functions ==============================

    /**
     * @notice Allows a user to vote on a survey
     * @param _surveyId The ID of the survey
     * @param _vote The user's vote (true/false)
     */
    function vote(uint256 _surveyId, bool _vote) external {
        ISurveyContract.Survey memory survey = surveyContract.getSurvey(_surveyId);
        require(survey.active, "Survey not active");
        require(block.timestamp <= survey.endTimestamp, "Voting period has ended");

        Vote storage userVote = surveyToVoterToVote[_surveyId][msg.sender];
        require(!userVote.voted, "Already voted");

        uint256 stakedAmount = stakingContract.userToTokenToStake(msg.sender, survey.tokenAddress);
        require(stakedAmount >= survey.minimumStake, "Insufficient stake for voting");

        userVote.voted = true;
        userVote.vote = _vote;

        surveyContract.afterVote(_surveyId, msg.sender, _vote);

        emit Voted(_surveyId, msg.sender, _vote);
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
     * @notice Function which reverts when `_msgSender()` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @param newImplementation Address of the new contract implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}
}
