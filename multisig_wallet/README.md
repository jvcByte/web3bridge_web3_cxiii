# Multi-Signature Wallet

A secure multi-signature wallet smart contract that requires multiple owners to approve transactions before execution.

## Features

- **Multi-owner governance**: Deploy with a list of owners and required confirmation threshold
- **Transaction submission**: Any owner can propose transactions (ETH transfers or contract calls)
- **Confirmation system**: Owners can confirm or revoke their confirmations
- **Secure execution**: Transactions execute only when enough confirmations are collected
- **ETH deposits**: Contract can receive ETH deposits
- **Custom errors**: Gas-efficient error handling instead of require statements
- **Event logging**: Comprehensive event emission for transaction lifecycle

## Smart Contract Overview

### Core Functions

- `submitTransaction(address to, uint256 value, bytes data)`: Submit a new transaction proposal
- `confirmTransaction(uint256 txId)`: Confirm a pending transaction
- `revokeConfirmation(uint256 txId)`: Revoke a previous confirmation
- `executeTransaction(uint256 txId)`: Execute a transaction when threshold is met

### View Functions

- `getOwners()`: Get list of all owners
- `getTransaction(uint256 txId)`: Get transaction details
- `isConfirmedBy(uint256 txId, address owner)`: Check if owner confirmed transaction
- `getConfirmationCount(uint256 txId)`: Get current confirmation count
- `getBalance()`: Get contract ETH balance

## Installation

```bash
npm install
```

## Compilation

```bash
npm run build
```

## Testing

Run the comprehensive test suite:

```bash
npm run test
```

Run tests with gas reporting:

```bash
npm run test:gas
```

Run coverage analysis:

```bash
npm run coverage
```

## Deployment

### Local deployment (Hardhat Network)

1. Start local network:
```bash
npm run node
```

2. Deploy to local network:
```bash
npm run deploy:local
```

### Testnet deployment

1. Configure your `.env` file:
```env
SEPOLIA_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. Deploy to Sepolia:
```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

## Usage Examples

### Basic Workflow

1. **Deploy** the contract with owners and required confirmations
2. **Fund** the wallet by sending ETH to the contract address
3. **Submit** a transaction proposal
4. **Confirm** the transaction with required number of owners
5. **Execute** the transaction once threshold is met

### Interaction Script

Run the interaction demo:

```bash
npx hardhat run scripts/interact.ts --network localhost
```

### Code Example

```typescript
import { ethers } from "hardhat";

// Deploy wallet with 3 owners, requiring 2 confirmations
const owners = [owner1.address, owner2.address, owner3.address];
const requiredConfirmations = 2;
const wallet = await MultiSigWallet.deploy(owners, requiredConfirmations);

// Submit ETH transfer
const txId = await wallet.connect(owner1).submitTransaction(
  recipient,
  ethers.parseEther("1.0"),
  "0x"
);

// Confirm with 2 owners
await wallet.connect(owner1).confirmTransaction(0);
await wallet.connect(owner2).confirmTransaction(0);

// Execute transaction
await wallet.connect(owner1).executeTransaction(0);
```

## Security Features

- **Access Control**: Only owners can submit, confirm, and execute transactions
- **Confirmation Threshold**: Configurable number of required confirmations
- **Revocation**: Owners can revoke confirmations before execution
- **Execution Protection**: Transactions can only be executed once
- **Input Validation**: Comprehensive validation with custom errors
- **Reentrancy Protection**: Safe external calls with proper state management

## Gas Optimization

- Custom errors instead of require strings
- Efficient storage layout
- Optimized loops and state access
- Minimal external calls

## Testing Coverage

The test suite covers:

- ✅ Constructor validation (owners, confirmations, duplicates, zero addresses)
- ✅ ETH deposits and balance tracking
- ✅ Transaction submission with data
- ✅ Confirmation and revocation workflows
- ✅ Execution with various scenarios
- ✅ Access control enforcement
- ✅ Error conditions and edge cases
- ✅ Multi-transaction workflows
- ✅ Gas optimization scenarios
- ✅ Complex confirmation patterns

## Contract Verification

After deployment, verify your contract on Etherscan:

```bash
npx hardhat verify --network sepolia DEPLOYED_CONTRACT_ADDRESS "CONSTRUCTOR_ARG1" "CONSTRUCTOR_ARG2"
```

## Development Scripts

- `npm run build`: Compile contracts
- `npm run test`: Run test suite
- `npm run test:gas`: Test with gas reporting
- `npm run coverage`: Generate coverage report
- `npm run deploy:local`: Deploy to local network
- `npm run node`: Start local Hardhat node
- `npm run clean`: Clean artifacts and cache


## Deployed Contract Information

Successfully deployed Multigiwallet on lisk-sepolia network 🚀

- Deployed Addresses - `0x2eD0a805fB90831c7EECaEe8863c12E5448BE5b8`
- Successfully verified contract - [View on blockscout](https://sepolia-blockscout.lisk.com/address/0x2eD0a805fB90831c7EECaEe8863c12E5448BE5b8#code)


## License

MIT
