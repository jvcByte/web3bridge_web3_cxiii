// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenName = "Amazon Token";
const tokenSymbol = "ZAM";
const tokenDecimals = 18;
const totalSupply = 1_000_000_000n;

const ERC20Module = buildModule("ERC20Module", (m) => {
  const name = m.getParameter("Token Name", tokenName);
  const symbol = m.getParameter("Token Symbol", tokenSymbol);
  const decimals = m.getParameter("Token Decimals", tokenDecimals);
  const supply = m.getParameter("Total Supply", totalSupply);

  const ERC20 = m.contract("ERC20", [name, symbol, decimals, supply]);

  return { ERC20 };
});

export default ERC20Module;
