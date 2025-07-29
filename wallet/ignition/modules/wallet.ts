// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";



const walletModule = buildModule("walletModule", (m) => {

    const lock = m.contract("jvcbyteWallet");

    return { lock };
});

export default walletModule;
