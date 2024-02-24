// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../Interfaces/IStaking.sol";
import "../Interfaces/ISurvey.sol";

contract Voting is UUPSUpgradeable, Initializable {


    // =========================== Variables & Declarations ==============================

    IStaking public stakingContract;

    struct Vote {
        bool voted;
        bool vote;
    }

    // =========================== Mappings ==============================

    // =========================== Events ==============================

    // =========================== View functions ==============================


    // =========================== Initializers ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice First initializer function
     * @param
     */
    function initialize(address _stakingContractAddress) public initializer {
        __UUPSUpgradeable_init();
        stakingContract = IStakingContract(_stakingContractAddress);
    }

    // =========================== Public functions ==============================


    function vote(uint256 _surveyId, bool _vote) public {
        Survey storage survey = surveys[_surveyId];
        require(survey.active, "Survey not active");
        require(!survey.votes[msg.sender].voted, "Already voted");

        uint256 stakedAmount = stakingContract.getStakedAmount(msg.sender);
        require(stakedAmount >= minimumStake, "Insufficient stake for voting");

        survey.votes[msg.sender] = Vote(true, _vote);
        if(_vote) {
            survey.yesCount++;
        } else {
            survey.noCount++;
        }
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
