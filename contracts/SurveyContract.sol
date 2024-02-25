// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../Interfaces/IStakingContract.sol";
import "../Interfaces/IVotingContract.sol";

contract SurveyContract is UUPSUpgradeable, Initializable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;


    // =========================== Variables & Declarations ==============================

    uint256 public surveyCost;

    bytes32 public constant VOTING_CONTRACT_ROLE = keccak256("VOTING_CONTRACT_ROLE");

    CountersUpgradeable.Counter public nextSurveyId;

    IStakingContract public stakingContract;

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


    mapping(uint256 => Survey) public surveys;


    // =========================== Events ==============================

    event SurveyCreated(uint256 surveyId, address owner, string descriptionUri, address tokenAddress, uint256 minimumStake, uint256 endTimestamp);

    event SurveyCancelled(uint256 surveyId);

    event SurveyCostUpdated(uint256 newCost);

    event SurveyVoted(uint256 surveyId, address voter, bool vote);


    // =========================== View functions ==============================

//    function getSurvey(uint256 surveyId) external view returns (Survey memory) {
//        return surveys[surveyId];
//    }


    // =========================== Initializers ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice First initializer function
     */
    function initialize(address _stakingContractAddress) public initializer {
        __AccessControl_init();
//        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Increment counter to start survey ids at index 1
        nextSurveyId.increment();
        stakingContract = IStakingContract(_stakingContractAddress);
        updateSurveyCost(1 ether);
    }

    // =========================== Public functions ==============================

    function updateSurveyCost (uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        surveyCost = _newCost;

        emit SurveyCostUpdated(_newCost);
    }

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

    function cancelSurvey(uint256 _surveyId) external {
        require(surveys[_surveyId].owner == msg.sender, "Not the owner");
        require(surveys[_surveyId].active, "Survey not active");
        surveys[_surveyId].active = false;

        emit SurveyCancelled(_surveyId);
    }

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
