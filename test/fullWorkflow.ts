import {BarERC20, StakingContract, SurveyContract, VotingContract} from "../typechain-types";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {ethers, upgrades} from "hardhat";
import {deploy} from "./utils/deploy";
import {expect} from "chai";
import {BigNumber} from "ethers";

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

        const allowedTokenList = [barToken.address]

        // Deployer adds a list of authorized tokens
        for (const tokenAddress of allowedTokenList) {
            await stakingContract
                .connect(deployer)
                .updateAllowedTokenList(tokenAddress, true);
        }

        // Deployer Transfers 2000 BAR from deployer to each address
        const decimals = await barToken.decimals();
        const amount = ethers.utils.parseUnits("2000", decimals);
        await barToken.connect(deployer).transfer(alice.address, amount);
        await barToken.connect(deployer).transfer(bob.address, amount);
        await barToken.connect(deployer).transfer(carol.address, amount);
    });


    describe("StakingContract Tests", function () {

        const stakeAmount = ethers.utils.parseEther("10");
        describe("Token Staking", function () {

            it("Should not allow approving address 0x", async function () {
                await expect(
                    stakingContract
                        .connect(deployer)
                        .updateAllowedTokenList(ethers.constants.AddressZero, true)
                ).to.be.revertedWith("Token address cannot be 0x0");
            });

            it("Should correctly update allowedTokenList", async function() {
                const randomTokenAddress = ethers.Wallet.createRandom().address;

                await stakingContract.connect(deployer).updateAllowedTokenList(randomTokenAddress, true);
                await stakingContract.connect(deployer).removeAllowedToken(randomTokenAddress);

                expect(await stakingContract.isTokenAllowed(randomTokenAddress)).to.equal(false);
            });

            it("Should allow staking of allowed tokens", async function () {
                await barToken.connect(alice).approve(stakingContract.address, stakeAmount);
                await expect(
                    stakingContract.connect(alice).stake(stakeAmount, barToken.address)
                ).to.emit(stakingContract, "Staked").withArgs(alice.address, barToken.address, stakeAmount);
            });

            it("Should only be callable by DEFAULT_ADMIN_ROLE", async function() {
                const randomTokenAddress = ethers.Wallet.createRandom().address;

                await expect(
                    stakingContract.connect(alice).removeAllowedToken(randomTokenAddress)
                ).to.be.reverted;

                await expect(
                    stakingContract.connect(deployer).removeAllowedToken(randomTokenAddress)
                ).not.to.be.reverted;
            });

            it("Should not allow staking of non-allowed tokens", async function () {
                const nonAllowedToken = ethers.Wallet.createRandom().address;
                await expect(
                    stakingContract.connect(alice).stake(stakeAmount, nonAllowedToken)
                ).to.be.revertedWith("Token not allowed");
            });

            it("Should correctly record staked amounts", async function () {
                const stakedAmount = await stakingContract.getStakedAmount(alice.address, barToken.address);
                expect(stakedAmount).to.equal(stakeAmount);
            });
        });

        describe("Token Unstaking", function () {
            const unstakeAmount = ethers.utils.parseEther("5");

            it("Should allow unstaking of staked tokens", async function () {
                await expect(
                    stakingContract.connect(alice).unStake(unstakeAmount, barToken.address)
                ).to.emit(stakingContract, "UnStaked").withArgs(alice.address, barToken.address, unstakeAmount);
            });

            it("Should not allow unstaking more than staked amount", async function () {
                const excessAmount = ethers.utils.parseEther("100");
                await expect(
                    stakingContract.connect(alice).unStake(excessAmount, barToken.address)
                ).to.be.revertedWith("Insufficient staked amount");
            });

            it("Should correctly update staked amounts after unstaking", async function () {
                const remainingStakedAmount = await stakingContract.getStakedAmount(alice.address, barToken.address);
                expect(remainingStakedAmount).to.equal(stakeAmount.sub(unstakeAmount));
            });
        });

        describe("Withdrawal of Contract Balance", function () {
            it("Should allow withdrawal by admin and reduce contract balance", async function () {
                const sendAmount = ethers.utils.parseEther("1.0"); // 1 ether for example
                await alice.sendTransaction({
                    to: stakingContract.address,
                    value: sendAmount
                });

                const initialContractBalance = await ethers.provider.getBalance(stakingContract.address);
                expect(initialContractBalance).to.equal(sendAmount);

                await stakingContract.connect(deployer).withdraw();

                const finalContractBalance = await ethers.provider.getBalance(stakingContract.address);

                expect(finalContractBalance).to.equal(0);
            });


            it("Should revert withdrawal by non-admin", async function () {
                await expect(
                    stakingContract.connect(alice).withdraw()
                ).to.be.reverted;
            });
        });
    });

    describe("SurveyContract Tests", function () {
        const surveyCost = ethers.utils.parseEther("1.0");
        const descriptionUri = "http://example.com/survey";
        const minimumStake = ethers.utils.parseEther("10");
        const durationInDays = 7; // Duration of the survey in days

        describe("Create Survey", function () {
            it("Should allow creating a survey with correct cost and parameters", async function () {
                const tx = await surveyContract.connect(alice).createSurvey(
                    barToken.address,
                    descriptionUri,
                    minimumStake,
                    durationInDays,
                    { value: surveyCost }
                );
                await expect(tx).to.emit(surveyContract, "SurveyCreated");
            });

            it("Should revert creating a survey with incorrect cost", async function () {
                await expect(
                    surveyContract.connect(alice).createSurvey(
                        barToken.address,
                        descriptionUri,
                        minimumStake,
                        durationInDays,
                        { value: ethers.utils.parseEther("0.5") }
                    )
                ).to.be.revertedWith("Incorrect amount of ETH for survey creation");
            });
        });

        describe("Cancel Survey", function () {
            it("Should allow the owner to cancel their survey", async function () {
                const nextSurveyId = await surveyContract.nextSurveyId();
                const surveyId = nextSurveyId.sub(BigNumber.from(1));
                await expect(
                    surveyContract.connect(alice).cancelSurvey(surveyId)
                ).to.emit(surveyContract, "SurveyCancelled");
            });

            it("Should revert cancellation by non-owner", async function () {
                const nextSurveyId = await surveyContract.nextSurveyId();
                const surveyId = nextSurveyId.sub(BigNumber.from(1));
                await expect(
                    surveyContract.connect(bob).cancelSurvey(surveyId)
                ).to.be.revertedWith("Not the owner");
            });
        });

        describe("Update Survey Cost", function () {
            it("Should allow admin to update survey cost", async function () {
                const newSurveyCost = ethers.utils.parseEther("2.0");
                await expect(
                    surveyContract.connect(deployer).updateSurveyCost(newSurveyCost)
                ).to.emit(surveyContract, "SurveyCostUpdated");
            });

            it("Should revert update by non-admin", async function () {
                const newSurveyCost = ethers.utils.parseEther("2.0");
                await expect(
                    surveyContract.connect(alice).updateSurveyCost(newSurveyCost)
                ).to.be.reverted;
            });
        });

        describe("Withdrawal of Contract Balance", function () {
            it("Should allow withdrawal by admin and reduce contract balance", async function () {
                const initialContractBalance = await ethers.provider.getBalance(surveyContract.address);
                const sendAmount = ethers.utils.parseEther("1.0"); // 1 ether for example
                await alice.sendTransaction({
                    to: surveyContract.address,
                    value: sendAmount
                });

                expect(initialContractBalance).to.equal(sendAmount);

                await surveyContract.connect(deployer).withdraw();

                const finalContractBalance = await ethers.provider.getBalance(surveyContract.address);

                expect(finalContractBalance).to.equal(0);
            });


            it("Should revert withdrawal by non-admin", async function () {
                await expect(
                    surveyContract.connect(alice).withdraw()
                ).to.be.reverted;
            });
        });
    });

    describe("VotingContract Tests", function () {
        // Survey details
        const surveyCost = ethers.utils.parseEther("2.0");
        const descriptionUri = "http://example.com/survey";
        const minimumStake = ethers.utils.parseEther("10");
        const durationInDays = 7; // Duration of the survey in days
        let surveyId: BigNumber;

        before(async function () {
            // Alice creates a survey and gets its ID
            await surveyContract.connect(alice).createSurvey(
                barToken.address,
                descriptionUri,
                minimumStake,
                durationInDays,
                { value: surveyCost }
            );
            surveyId = (await surveyContract.nextSurveyId()).sub(1); // Get the last created surveyId
        });

        describe("Voting in Surveys", function () {
            it("Should allow voting if the user has staked enough tokens", async function () {
                // Alice stakes enough tokens to vote
                await barToken.connect(alice).approve(stakingContract.address, minimumStake);
                await stakingContract.connect(alice).stake(minimumStake, barToken.address);

                // Alice votes in the survey
                await expect(
                    votingContract.connect(alice).vote(surveyId, true)
                ).to.emit(votingContract, "Voted").withArgs(surveyId, alice.address, true);

                expect(await votingContract.hasVoted(surveyId, alice.address)).to.equal(true);

                // Carol stakes enough tokens to vote
                await barToken.connect(carol).approve(stakingContract.address, minimumStake);
                await stakingContract.connect(carol).stake(minimumStake, barToken.address);

                // Carol votes in the survey
                await expect(
                    votingContract.connect(carol).vote(surveyId, false)
                ).to.emit(votingContract, "Voted").withArgs(surveyId, carol.address, false);

                expect(await votingContract.hasVoted(surveyId, carol.address)).to.equal(true);
            });

            it("Should not allow voting without sufficient stake", async function () {
                // Bob tries to vote without staking
                await expect(
                    votingContract.connect(bob).vote(surveyId, true)
                ).to.be.revertedWith("Insufficient stake for voting");
            });

            it("Should not allow double voting", async function () {
                // Alice tries to vote again in the same survey
                await expect(
                    votingContract.connect(alice).vote(surveyId, false)
                ).to.be.revertedWith("Already voted");
            });

            it("Should update the survey vote count", async function () {
                const surveyId = 2; // Survey in which Alice voted "true"
                const survey = await surveyContract.getSurvey(surveyId);
                expect(survey.yesCount).to.equal(1); // 1 vote for
                expect(survey.noCount).to.equal(1); // 1 vote against
            })

            it("Should revert when called by an admin without VOTING_CONTRACT_ROLE", async function () {
                const surveyId = 2;
                const voterAddress = alice.address; // Assuming Alice has participated in the survey
                const vote = true;
                const votingContractRole = await surveyContract.VOTING_CONTRACT_ROLE();

                // Attempt to call afterVote as an admin (deployer)
                await expect(
                    surveyContract.connect(deployer).afterVote(surveyId, voterAddress, vote)
                ).to.be.revertedWith("AccessControl: account " + deployer.address.toLowerCase() + " is missing role " + votingContractRole);
            });
        });

        describe("Withdrawal of Contract Balance", function () {
            it("Should allow withdrawal by admin and reduce contract balance", async function () {
                const sendAmount = ethers.utils.parseEther("1.0");
                await alice.sendTransaction({
                    to: votingContract.address,
                    value: sendAmount
                });

                const initialContractBalance = await ethers.provider.getBalance(votingContract.address);
                expect(initialContractBalance).to.equal(sendAmount);

                await votingContract.connect(deployer).withdraw();

                const finalContractBalance = await ethers.provider.getBalance(votingContract.address);
                expect(finalContractBalance).to.equal(0);
            });

            it("Should revert withdrawal by non-admin", async function () {
                await expect(
                    votingContract.connect(alice).withdraw()
                ).to.be.reverted;
            });
        });
    });

    describe("_authorizeUpgrade Function", function() {
        it("Should only allow upgrade by DEFAULT_ADMIN_ROLE", async function() {
            const NewStakingContract = await ethers.getContractFactory("StakingContract");

            await expect(
                upgrades.upgradeProxy(stakingContract.address, NewStakingContract)
            ).not.to.be.reverted;
        });

        it("Should only allow upgrade by DEFAULT_ADMIN_ROLE", async function() {
            const NewSurveyContract = await ethers.getContractFactory("SurveyContract");

            await expect(
                upgrades.upgradeProxy(surveyContract.address, NewSurveyContract)
            ).not.to.be.reverted;
        });

        it("Should only allow upgrade by DEFAULT_ADMIN_ROLE", async function() {
            const NewVotingContract = await ethers.getContractFactory("VotingContract");

            await expect(
                upgrades.upgradeProxy(votingContract.address, NewVotingContract)
            ).not.to.be.reverted;
        });
    });
});