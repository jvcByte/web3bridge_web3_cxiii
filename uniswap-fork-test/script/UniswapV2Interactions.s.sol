// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/interfaces/IUniswapV2Factory.sol";
import "../src/interfaces/IUniswapV2Pair.sol";
import "../src/interfaces/IUniswapV2Router02.sol";
import "../src/interfaces/IERC20.sol";
import "../src/interfaces/IWETH.sol";




contract UniswapV2Interactions is Script {

    address constant ROUTER  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI     = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // DAI whale (Binance hot wallet)
    address constant DAI_WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;
    
    error DAI_APPROVAL_FAILED();
    error WETH_APPROVAL_FAILED();
    
    function padLeft(string memory _str, uint256 _length, bytes1 _padChar) internal pure returns (string memory) {
        bytes memory _bytes = bytes(_str);
        if (_bytes.length >= _length) {
            return _str;
        }
        bytes memory _padded = new bytes(_length);
        uint256 _start = _length - _bytes.length;
        for (uint256 i = 0; i < _length; i++) {
            _padded[i] = i < _start ? _padChar : _bytes[i - _start];
        }
        return string(_padded);
    }

    function formatTokenAmount(uint256 amount, uint8 decimals) public pure returns (string memory) {
        uint256 whole = amount / 10**decimals;
        uint256 fractional = amount % 10**decimals;
        return string(abi.encodePacked(
            Strings.toString(whole),
            ".",
            padLeft(Strings.toString(fractional), decimals, "0")
        ));
    }

    function getPairAddress(address tokenA, address tokenB) public view returns (address) {
        return IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);
    }

    function run() external {
        console.log("Current fork block:", block.number);
        console.log("Block timestamp:", block.timestamp);
        
        IERC20 dai = IERC20(DAI);
        IERC20 weth = IERC20(WETH);
        IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
        
        console.log("\n=== Initial Balances ===");
        console.log(string(abi.encodePacked("DAI Balance of DAI_WHALE: ", formatTokenAmount(dai.balanceOf(DAI_WHALE), 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Balance of DAI_WHALE: ", formatTokenAmount(weth.balanceOf(DAI_WHALE), 18), " WETH")));
        
        vm.startPrank(DAI_WHALE);
        
        console.log("\n=== 1. Pool Address ===");
        address pair = getPairAddress(WETH, DAI);
        
        if (pair == address(0)) {
            console.log("Creating new DAI-WETH pair...");
            IUniswapV2Factory factory = IUniswapV2Factory(FACTORY);
            pair = factory.createPair(WETH, DAI);
            console.log("New pair created:", pair);
            
            // Add initial liquidity to the new pair
            console.log("\n=== Adding Initial Liquidity ===");
            uint256 amountADesired = 10 * 1e18; 
            uint256 amountBDesired = 0.01 * 1e18; 
            
            // Approve router to spend tokens
            require(dai.approve(address(router), amountADesired), DAI_APPROVAL_FAILED());
            require(weth.approve(address(router), amountBDesired), WETH_APPROVAL_FAILED());
            
            // Add liquidity
            (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
                DAI,
                WETH,
                amountADesired,
                amountBDesired,
                (amountADesired * 99) / 100, // 1% slippage
                (amountBDesired * 99) / 100, // 1% slippage
                DAI_WHALE,
                block.timestamp + 300
            );
            
            console.log(string(abi.encodePacked("Added ", formatTokenAmount(amountA, 18), " DAI and ", 
                formatTokenAmount(amountB, 18), " WETH as initial liquidity")));
            console.log("Liquidity tokens minted:", liquidity);
            
        } else {
            console.log("Using existing DAI-WETH pair:", pair);
        }
        
        console.log("\n=== 2. Pool Reserves ===");
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        console.log(string(abi.encodePacked("DAI Reserve: ", formatTokenAmount(reserve0, 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Reserve: ", formatTokenAmount(reserve1, 18), " WETH")));
        
        console.log("\n=== 3. Calculate Swap ===");
        uint256 amountIn = 1000 * 1e18; // 1000 DAI
        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;
        
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256 expectedAmountOut = amounts[1];
        
        console.log(string(abi.encodePacked("Swapping ", formatTokenAmount(amountIn, 18), " DAI for ~", formatTokenAmount(expectedAmountOut, 18), " WETH")));
        
        console.log("\n=== 4. Execute Swap ===");
        uint256 minAmountOut = (expectedAmountOut * 95) / 100; // 5% slippage
        
        require(dai.approve(address(router), amountIn), DAI_APPROVAL_FAILED());
        
        uint256[] memory swapResult = router.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            path,
            DAI_WHALE,
            block.timestamp + 300
        );
        
        console.log(string(abi.encodePacked("Received: ", formatTokenAmount(swapResult[1], 18), " WETH")));
        
        console.log("\n=== Reserves Balance After Swap ===");
        (uint112 finalReserve0, uint112 finalReserve1,) = IUniswapV2Pair(pair).getReserves();
        console.log(string(abi.encodePacked("DAI Reserve: ", formatTokenAmount(finalReserve0, 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Reserve: ", formatTokenAmount(finalReserve1, 18), " WETH")));
        
        console.log("\n=== Balances After Swap ===");
        console.log(string(abi.encodePacked("DAI Balance: ", formatTokenAmount(dai.balanceOf(DAI_WHALE), 18), " DAI")));
        console.log(string(abi.encodePacked("WETH Balance: ", formatTokenAmount(weth.balanceOf(DAI_WHALE), 18), " WETH")));
        
        vm.stopPrank();
    }
}