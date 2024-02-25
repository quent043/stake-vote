// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../Interfaces/IStakingContract.sol";
import "../Interfaces/ISurveyContract.sol";

contract VotingContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {


    // =========================== Variables & Declarations ==============================

    IStakingContract public stakingContract;
    ISurveyContract public surveyContract;

    struct Vote {
        bool voted;
        bool vote;
    }

    // =========================== Mappings ==============================

    mapping(uint256 => mapping(address => Vote)) public surveyToVoterToVote;

    // =========================== Events ==============================

    event Voted(uint256 surveyId, address voter, bool vote);


    // =========================== View functions ==============================

    function hasVoted(uint256 _surveyId, address _voter) external view returns (bool) {
        return surveyToVoterToVote[_surveyId][_voter].voted;
    }

    // =========================== Initializers ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice First initializer function
     */
    function initialize(address _stakingContractAddress, address _surveyContractAddress) public initializer {
//        __UUPSUpgradeable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingContract = IStakingContract(_stakingContractAddress);
        surveyContract = ISurveyContract(_surveyContractAddress);
    }

    // =========================== Public functions ==============================


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
     * Allow receiving of ETH
     */
    receive() external payable {}

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
