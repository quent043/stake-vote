import {ethers, upgrades} from "hardhat";
import {StakingContract, SurveyContract, VotingContract, BarERC20} from "../../typechain-types";

//TODO double check variables in constructors, ya eu des changements
export async function deploy(): Promise<[StakingContract, SurveyContract, VotingContract, BarERC20]> {
    // Deploy Staking Contract
    const Staking = await ethers.getContractFactory('Staking');
    const staking = await upgrades.deployProxy(Staking, [], { initializer: 'initialize' });
    await staking.deployed();
    console.log('Staking deployed to:', staking.address);

    // Deploy Survey Contract
    const Survey = await ethers.getContractFactory('Survey');
    const surveyContractArgs = [staking.address];
    const survey = await upgrades.deployProxy(Survey, surveyContractArgs, { initializer: 'initialize' });
    await survey.deployed();
    console.log('Survey deployed to:', survey.address);

    // Deploy Voting Contract
    const Voting = await ethers.getContractFactory('Voting');
    const votingContractArgs = [staking.address, survey.address];
    const voting = await upgrades.deployProxy(Voting, votingContractArgs, { initializer: 'initialize' });
    await voting.deployed();
    console.log('Voting deployed to:', voting.address);

    // Deploy BatToken Token
    const BarErc20 = await ethers.getContractFactory('BarERC20')
    const barErc20 = await BarErc20.deploy()

    return  [staking as StakingContract, survey as SurveyContract, voting as VotingContract, barErc20 as BarERC20];
}

deploy()
    .then((contracts) => console.log('Contracts deployed successfully:', contracts))
    .catch((error) => console.error('An error occurred during deployment:', error));
