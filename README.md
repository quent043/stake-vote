# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```


----

# Possible Improvements

 - Implement a Pausable strategy
 - Add Arbitration (in case of a hack, to render a survey null)
 - Add NFT owning to  voting conditions
 - Use Viem (didn't have time to find good viem tools for UUPS proxy deployments)
 - Add a locking period in staking contract. Tokens are locked for the duration of the survey and can be redeemed after the end timestamp.
