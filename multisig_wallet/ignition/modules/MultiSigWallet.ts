// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const REQUIRED_CONFIRMATIONS = 2;

const MultiSigWalletModule = buildModule("MultiSigWalletModule", (m) => {
  // Define owner addresses as parameters with default values
  const owner1 = m.getParameter("owner1", "0x2CE7756B09e0BE1306aC18d0968D36F259c76447");
  const owner2 = m.getParameter("owner2", "0x1234567890123456789012345678901234567890");
  const owner3 = m.getParameter("owner3", "0x1234567890123456789012345678901234567891");

  const owners = [owner1, owner2, owner3];

  // Deploy the MultiSigWallet contract
  const multiSigWallet = m.contract("MultiSigWallet", [
    owners,
    REQUIRED_CONFIRMATIONS,
  ]);

  return { multiSigWallet };
});

export default MultiSigWalletModule;
