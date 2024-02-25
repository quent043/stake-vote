import { HardhatUserConfig } from "hardhat/config";
import '@nomicfoundation/hardhat-toolbox'
import '@openzeppelin/hardhat-upgrades'
import '@openzeppelin/hardhat-defender'
import "solidity-coverage";


const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
