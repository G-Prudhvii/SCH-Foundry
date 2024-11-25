// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface cERC20 is IERC20 {
    function mint(uint256) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function exchangeRateCurrent() external view returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function underlying() external view returns (address);
    function balanceOfUnderlying(address owner) external view returns (uint256);
}

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);
}
