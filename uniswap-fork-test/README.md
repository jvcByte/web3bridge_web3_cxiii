Alright — we’ll go **full Foundry** so you can fork Ethereum mainnet locally, interact with Uniswap V2 contracts, and call at least 5 different functions.
We’ll cover: setup, configuration, running anvil, writing a Solidity script, impersonating whales, and interacting with Uniswap V2.

---

## **1. Install Foundry**

If you haven’t installed Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Verify:

```bash
forge --version
anvil --version
```

---

## **2. Create Project**

```bash
mkdir foundry-uniswap-v2 && cd foundry-uniswap-v2
forge init
```

This gives you:

* `src/` for contracts
* `script/` for Solidity scripts
* `test/` for tests

---

## **3. Get RPC URL**

You need an **Ethereum archive** or near-archive RPC for forking.
Use [Alchemy](https://alchemy.com) or [Infura](https://infura.io) and set it in `.env`:

```bash
echo 'MAINNET_RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR_KEY"' >> .env
```

---

## **4. Configure `foundry.toml`**

Edit the `foundry.toml` to enable forking:

```toml
[default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"

[profile.default]
fork_block_number = 17500000 # Optional: deterministic results
```

---

## **5. Uniswap V2 Addresses**

We’ll use:

```solidity
address constant ROUTER  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
address constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI     = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
```

---

## **6. Enhanced Uniswap V2 Interaction Script**

Our script provides a robust interface to interact with Uniswap V2, featuring:

1. **Automatic Pair Creation**: Creates new liquidity pairs if they don't exist
2. **Detailed Logging**: Human-readable output with proper decimal formatting
3. **Slippage Protection**: Configurable minimum output amount (default 5% slippage)
4. **Whale Impersonation**: Test with large token balances using known whale addresses
5. **Comprehensive Info**: View pool reserves, token balances, and swap details

---

### **`script/UniswapV2Interactions.s.sol`**

This script demonstrates advanced interaction with Uniswap V2, including automatic pair creation and detailed logging.

#### Key Features:
- **Automatic Pair Creation**: Creates new liquidity pairs if they don't exist
- **Detailed Logging**: Human-readable output with proper decimal formatting
- **Slippage Protection**: Configurable minimum output amount (default 5% slippage)
- **Whale Impersonation**: Test with large token balances using known whale addresses
- **Comprehensive Info**: View pool reserves, token balances, and swap details

#### Interfaces Used:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Minimal interfaces for Uniswap V2
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] calldata path) 
        external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapV2Interactions is Script {
    // Uniswap V2 contract addresses
    address constant ROUTER  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    // Token addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    // Known DAI whale address (Binance hot wallet)
    address constant DAI_WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;

    // Helper function to format token amounts with full precision
    function formatTokenAmount(uint256 amount, uint8 decimals) public pure returns (string memory) {
        uint256 whole = amount / 10**decimals;
        uint256 fractional = amount % 10**decimals;
        return string(abi.encodePacked(
            Strings.toString(whole),
            ".",
            Strings.toString(fractional)
        ));
    }

    // Get or create pair address
    function getPairAddress(address tokenA, address tokenB) public view returns (address) {
        return IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);
    }

    function run() external {
        console.log("Current fork block:", block.number);
        console.log("Block timestamp:", block.timestamp);
        
        // Initialize token and router interfaces
        IERC20 dai = IERC20(DAI);
        IERC20 weth = IERC20(WETH);
        IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
        
        // Log initial balances
        console.log("\n=== Initial Balances ===");
        console.log(string(abi.encodePacked("DAI Balance: ", formatTokenAmount(dai.balanceOf(DAI_WHALE), 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Balance: ", formatTokenAmount(weth.balanceOf(DAI_WHALE), 18), " WETH")));
        
        // Start impersonating the whale
        vm.startPrank(DAI_WHALE);
        
        // 1. Get or create pair address
        console.log("\n=== 1. Pool Address ===");
        address pair = getPairAddress(WETH, DAI);
        
        if (pair == address(0)) {
            console.log("Creating new DAI-WETH pair...");
            IUniswapV2Factory factory = IUniswapV2Factory(FACTORY);
            pair = factory.createPair(WETH, DAI);
            console.log("New pair created:", pair);
        } else {
            console.log("Using existing DAI-WETH pair:", pair);
        }
        
        // 2. Get reserves
        console.log("\n=== 2. Pool Reserves ===");
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        console.log(string(abi.encodePacked("DAI Reserve: ", formatTokenAmount(reserve0, 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Reserve: ", formatTokenAmount(reserve1, 18), " WETH")));
        
        // 3. Calculate swap amount
        console.log("\n=== 3. Calculate Swap ===");
        uint256 amountIn = 1000 * 1e18; // 1000 DAI
        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;
        
        // Get expected output using router's getAmountsOut
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256 expectedAmountOut = amounts[1];
        
        console.log(string(abi.encodePacked("Swapping ", formatTokenAmount(amountIn, 18), " DAI for ~", 
            formatTokenAmount(expectedAmountOut, 18), " WETH")));
        
        // 4. Execute swap with 5% slippage
        console.log("\n=== 4. Execute Swap ===");
        uint256 minAmountOut = (expectedAmountOut * 95) / 100; // 5% slippage
        
        // Approve router to spend DAI
        require(dai.approve(address(router), amountIn), "Approval failed");
        
        // Execute swap using router's swapExactTokensForTokens
        uint256[] memory swapResult = router.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            path,
            DAI_WHALE,
            block.timestamp + 300
        );
        
        // 5. Log results
        console.log("\n=== 5. Swap Complete ===");
        console.log(string(abi.encodePacked("Received: ", formatTokenAmount(swapResult[1], 18), " WETH")));
        
        // 6. Verify reserves after swap
        console.log("\n=== 6. Final Reserves ===");
        (uint112 finalReserve0, uint112 finalReserve1,) = IUniswapV2Pair(pair).getReserves();
        console.log(string(abi.encodePacked("DAI Reserve: ", formatTokenAmount(finalReserve0, 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Reserve: ", formatTokenAmount(finalReserve1, 18), " WETH")));
        
        // 7. Final balances
        console.log("\n=== 7. Final Balances ===");
        console.log(string(abi.encodePacked("DAI Balance: ", formatTokenAmount(dai.balanceOf(DAI_WHALE), 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Balance: ", formatTokenAmount(weth.balanceOf(DAI_WHALE), 18), " WETH")));
        
        vm.stopPrank();
    }
}
```

---

## **7. Run Anvil Fork**

In one terminal, start a local fork of Ethereum mainnet:

```bash
# Source your environment variables
source .env

# Start Anvil with forking from the latest block
anvil --fork-url $MAINNET_RPC_URL --fork-block-number 17500000
```

This will start a local Ethereum node forked from mainnet at the specified block number.

---

## **8. Run the Script**

In another terminal, execute the script using Foundry's `forge` command:

```bash
# Run the script on the local fork
forge script script/UniswapV2Interactions.s.sol:UniswapV2Interactions \
    --rpc-url http://localhost:8545 \
    --broadcast \
    -vvv
```

### Expected Output

When you run the script, you should see output similar to the following:

```
Current fork block: 17500000
Block timestamp: 1650000000

=== Initial Balances ===
DAI Balance: 9266206.791218982136922734 DAI
WETH Balance: 228.976237737393976027 WETH

=== 1. Pool Address ===
Using existing DAI-WETH pair: 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11

=== 2. Pool Reserves ===
DAI Reserve: 7303314.684690277716267613 DAI
WETH Reserve: 1718.400552615584182739 WETH

=== 3. Calculate Swap ===
Swapping 1000.000000000000000000 DAI for ~0.234552607407029564 WETH

=== 4. Execute Swap ===

=== 5. Swap Complete ===
Received: 0.234552607407029564 WETH

=== 6. Final Reserves ===
DAI Reserve: 7304314.684690277716267613 DAI
WETH Reserve: 1718.166000008177153175 WETH

=== 7. Final Balances ===
DAI Balance: 9265206.791218982136922734 DAI
WETH Balance: 229.210790344801005591 WETH
```

## **9. Understanding the Output**

1. **Initial Setup**: Shows the current block number and timestamp of the fork
2. **Initial Balances**: Displays the DAI and WETH balances of the whale address
3. **Pool Address**: Shows whether it's using an existing pair or creating a new one
4. **Pool Reserves**: Displays the current reserves in the liquidity pool
5. **Swap Calculation**: Shows the swap details including expected output
6. **Swap Execution**: Executes the swap with 5% slippage protection
7. **Final State**: Shows the updated reserves and balances after the swap

## **10. Customization**

You can modify the following variables in the script:
- `amountIn`: The amount of input tokens to swap
- `minAmountOut`: The minimum amount of output tokens to accept (slippage protection)
- `path`: The token swap path (e.g., DAI → WETH or WETH → DAI)

```bash
forge script script/UniswapV2Interactions.s.sol:UniswapV2Interactions \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast
```

---

## **9. What This Does**

* Forks Ethereum mainnet locally.
* Calls 5 different Uniswap V2 functions:

  1. `getPair` (factory)
  2. `getReserves` (pair)
  3. `getAmountsOut` (router)
  4. `approve` (ERC20)
  5. `swapExactTokensForTokens` (router)
* Uses **vm.startPrank** to impersonate a whale.
* Logs outputs to the terminal.

---

## **10. Notes**

* On a fork, `vm.startPrank(DAI_WHALE)` lets you act as that account.
* You can change `amountIn` or token addresses to try other swaps.
* Always pin a `fork_block_number` for deterministic results.
* If you don’t want to impersonate a whale, you can also **set balances**:

```solidity
vm.deal(DAI_WHALE, 100 ether); // Give ETH for gas
```

---

If you want, I can extend this guide with:

* **Liquidity add/remove example**
* **Reading historical prices from pair reserves**
* **Swapping multiple hops (3+ tokens)**

Do you want me to expand this into a **full Uniswap V2 Foundry playground repo** with those extra examples? That way you can run dozens of functions from one place.
