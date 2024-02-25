// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../Interfaces/IStakingContract.sol";
import "../Interfaces/IVotingContract.sol";

/**
 * @title Survey Contract
 * @notice This contract manages the creation, cancellation, and voting of surveys.
 * @author Quentin D.C.
 * @dev Utilizes UUPS (Universal Upgradeable Proxy Standard) for upgradability.
 */
contract SurveyContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // =========================== Variables & Declarations ==============================

    /**
     * @notice The cost to create a survey
     */
    uint256 public surveyCost;

    /**
     * @notice Role identifier for the voting contract
     */
    bytes32 public constant VOTING_CONTRACT_ROLE = keccak256("VOTING_CONTRACT_ROLE");

    /**
     * @notice Counter for tracking survey IDs
     */
    CountersUpgradeable.Counter public nextSurveyId;

    /**
     * @notice Staking Contract interface
     */
    IStakingContract public stakingContract;

    /**
     * @notice Structure to store survey details
     */
    struct Survey {
        address owner;
        string descriptionUri;
        bool active;
        address tokenAddress;
        uint256 yesCount;
        uint256 noCount;
        uint256 minimumStake;
        uint256 endTimestamp;
    }

    // =========================== Mappings ==============================

    /**
     * @notice Mapping from survey ID to Survey struct
     */
    mapping(uint256 => Survey) public surveys;

    // =========================== Events ==============================

    /**
     * @notice Event emitted when a survey is created
     */
    event SurveyCreated(uint256 surveyId, address owner, string descriptionUri, address tokenAddress, uint256 minimumStake, uint256 endTimestamp);

    /**
     * @notice Event emitted when a survey is cancelled
     */
    event SurveyCancelled(uint256 surveyId);

    /**
     * @notice Event emitted when the survey cost is updated
     */
    event SurveyCostUpdated(uint256 newCost);

    /**
     * @notice Event emitted when a vote is recorded on a survey
     */
    event SurveyVoted(uint256 surveyId, address voter, bool vote);

    // =========================== View functions ==============================

    /**
     * @notice Retrieves a survey by its ID
     * @param surveyId The ID of the survey
     * @return Survey Returns the survey struct
     */
    function getSurvey(uint256 surveyId) external view returns (Survey memory) {
        return surveys[surveyId];
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
     * @notice Initializes the contract with the staking contract address
     * @param _stakingContractAddress The address of the staking contract
     */
    function initialize(address _stakingContractAddress) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Increment counter to start survey ids at index 1
        nextSurveyId.increment();
        stakingContract = IStakingContract(_stakingContractAddress);
        updateSurveyCost(1 ether);
    }

    // =========================== Public functions ==============================

    /**
     * @notice Updates the cost to create a survey
     * @param _newCost The new cost for creating a survey
     */
    function updateSurveyCost (uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        surveyCost = _newCost;
        emit SurveyCostUpdated(_newCost);
    }

    /**
     * @notice Creates a new survey
     * @param _tokenAddress The address of the token to be staked for voting
     * @param _descriptionUri The URI containing the survey description
     * @param _minimumStake The minimum stake required to vote in the survey
     * @param _durationInDays The duration of the survey in days
     */
    function createSurvey(
        address _tokenAddress,
        string calldata _descriptionUri,
        uint256 _minimumStake,
        uint256 _durationInDays
    ) payable public {
        require(stakingContract.isTokenAllowed(_tokenAddress) == true, "Token not allowed");
        require(msg.value == surveyCost, "Incorrect amount of ETH for survey creation");

        uint256 currentSurveyId = nextSurveyId.current();
        uint256 endTimeStamp = block.timestamp + _durationInDays * 1 days;

        surveys[currentSurveyId] = Survey({
            owner: msg.sender,
            descriptionUri: _descriptionUri,
            active: true,
            tokenAddress: _tokenAddress,
            yesCount: 0,
            noCount: 0,
            minimumStake: _minimumStake,
            endTimestamp: endTimeStamp
        });

        nextSurveyId.increment();

        emit SurveyCreated(currentSurveyId, msg.sender, _descriptionUri, _tokenAddress, _minimumStake, endTimeStamp);
    }

    /**
     * @notice Cancels an active survey
     * @param _surveyId The ID of the survey to cancel
     */
    function cancelSurvey(uint256 _surveyId) external {
        require(surveys[_surveyId].owner == msg.sender, "Not the owner");
        require(surveys[_surveyId].active, "Survey not active");
        surveys[_surveyId].active = false;

        emit SurveyCancelled(_surveyId);
    }

    /**
     * @notice Records a vote on a survey, can only be called by the voting contract
     * @param _surveyId The ID of the survey
     * @param _voterAddress The address of the voter
     * @param _vote The vote (true for yes, false for no)
     */
    function afterVote(uint256 _surveyId, address _voterAddress, bool _vote) external onlyRole(VOTING_CONTRACT_ROLE) {
        Survey storage survey = surveys[_surveyId];
        require(survey.active, "Survey not active");
        if (_vote) {
            survey.yesCount += 1;
        } else {
            survey.noCount += 1;
        }

        emit SurveyVoted(_surveyId, _voterAddress, _vote);
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
     * @notice Function that reverts when `_msgSender()` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @param newImplementation Address of the new contract implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}

}
