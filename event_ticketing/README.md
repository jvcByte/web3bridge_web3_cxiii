## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```



Deployer: 0x2CE7756B09e0BE1306aC18d0968D36F259c76447
Deployed to: 0x10e4d4120a107422d4292382D09Fc86821fa3f82
Transaction hash: 0xea9957dbed8be9f45af5c205f15645ee86bd05846f8b26d0912a637753a00a8b
Starting contract verification...
Waiting for sourcify to detect contract deployment...
Start verifying contract `0x10e4d4120a107422d4292382D09Fc86821fa3f82` deployed on base-sepolia
Compiler version: 0.8.30



##### base-sepolia
✅  [Success] Hash: 0x0b84fc4b7e2f6108a2d4c4a75489d9604f5294d588234527573828abfe64f53a
Contract Address: 0xC9e989267bD52b14e9048dCfFe5d03Bc6e00d164
Block: 29453829
Paid: 0.000001139450527006 ETH (1139389 gas * 0.001000054 gwei)

✅ Sequence #1 on base-sepolia | Total Paid: 0.000001139450527006 ETH (1139389 gas * avg 0.001000054 gwei)
                                                                                                                                                  

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (1) contracts
Start verifying contract `0xC9e989267bD52b14e9048dCfFe5d03Bc6e00d164` deployed on base-sepolia
EVM version: cancun
Compiler version: 0.8.30
Optimizations:    200
Constructor args: 00000000000000000000000010e4d4120a107422d4292382d09fc86821fa3f82

Submitting verification for [src/LosslessBiddingContract.sol:LosslessBiddingContract] 0xC9e989267bD52b14e9048dCfFe5d03Bc6e00d164.
Submitted contract for verification:
        Response: `OK`
        GUID: `iwj49icqfv8h8gfhbd9ugvefysnqhhn5gca2pnuagqnbnk3ttt`
        URL: https://sepolia.basescan.org/address/0xc9e989267bd52b14e9048dcffe5d03bc6e00d164
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
All (1) contracts were verified!

Transactions saved to: /home/jvcbyte/Downloads/web3bridge_xiii/event_ticketing/broadcast/DeployLosslessBidding.s.sol/84532/run-latest.json

Sensitive values saved to: /home/jvcbyte/Downloads/web3bridge_xiii/event_ticketing/cache/DeployLosslessBidding.s.sol/84532/run-latest.json