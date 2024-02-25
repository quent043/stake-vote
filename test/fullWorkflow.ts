import {BarERC20, StakingContract, SurveyContract, VotingContract} from "../typechain-types";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {ethers} from "hardhat";
import {deploy} from "./utils/deploy";
import {expect} from "chai";

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

        // Deployer Transfers 2000 BAR from deployer to each address
        const amount = ethers.utils.parseEther("2000");
        await barToken.connect(deployer).transfer(alice.address, amount);
        await barToken.connect(deployer).transfer(bob.address, amount);
        await barToken.connect(deployer).transfer(carol.address, amount);
    });


    describe("StakingContract Tests", function () {

        const stakeAmount = ethers.utils.parseEther("10"); // 10 tokens
        describe("Token Staking", function () {

            it("Should allow staking of allowed tokens", async function () {
                await barToken.connect(alice).approve(stakingContract.address, stakeAmount);
                await expect(
                    stakingContract.connect(alice).stake(stakeAmount, barToken.address)
                ).to.emit(stakingContract, "Staked").withArgs(alice.address, barToken.address, stakeAmount);
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
            const unstakeAmount = ethers.utils.parseEther("5"); // Unstaking 5 tokens

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

});