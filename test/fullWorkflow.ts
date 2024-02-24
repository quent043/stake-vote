import {BarERC20, StakingContract, SurveyContract, VotingContract} from "../typechain-types";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {ethers} from "hardhat";
import {deploy} from "./utils/deploy";

describe('Voting Staking global testing', function () {
    let deployer: SignerWithAddress,
        alice: SignerWithAddress,
        bob: SignerWithAddress,
        carol: SignerWithAddress,
        stakingContract: StakingContract,
        surveyContract: SurveyContract,
        votingContract: VotingContract,
        barToken: BarERC20

    before(async function () {
        // Get the Signers
        ;[deployer, alice, bob, carol] = await ethers.getSigners()
        ;[
            stakingContract,
            surveyContract,
            votingContract,
            barToken
        ] = await deploy()

        const allowedTokenList = [
            ethers.constants.AddressZero,
            barToken.address,
        ]

        // Deployer adds a list of authorized tokens
        for (const tokenAddress of allowedTokenList) {
            await stakingContract
                .connect(deployer)
                .updateAllowedTokenList(tokenAddress, true);
        }
    });

});