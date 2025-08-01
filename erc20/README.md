# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```
Deployment Script:
npx hardhat ignition deploy ignition/modules/PrizeClaimContract.ts --network lisk-sepolia --deployment-id PrizeClaimContract-deployment --verify


Contract address - 0x3E15D0B3351A2C8a9646bC20b53648D42cE5610F