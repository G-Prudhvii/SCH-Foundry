// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Chocolate} from "../../src/8. Dex-1/Chocolate.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Pair} from "../../src/interfaces/IUniswapV2.sol";

contract TestChocolate is Test {
    Chocolate chocolate;
    IUniswapV2Pair pair;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");

    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant RICH_SIGNER = 0x8EB8a3b98659Cce290402893d0123abb75E3ab28;
    IERC20 weth = IERC20(WETH_ADDRESS);
    uint256 constant ETH_BALANCE = 300 ether;

    uint256 constant INITIAL_MINT = 1000000 ether;
    uint256 constant INITIAL_LIQUIDITY = 100000 ether;
    uint256 constant ETH_IN_LIQUIDITY = 100 ether;
    uint256 constant TEN_ETH = 10 ether;
    uint256 constant HUNDRED_CHOCOLATES = 100 ether;

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(user, 100 ether);

        // TODO: Deploy your smart contract to `this.chocolate`, mint 1,000,000 tokens to deployer
        vm.prank(deployer);
        chocolate = new Chocolate(INITIAL_MINT);

        // TODO: Print newly created pair address and store pair contract to `this.pair`
        console.log("Pair address: ", chocolate.uniswapV2Pair());
        pair = IUniswapV2Pair(chocolate.uniswapV2Pair());

        // forge test -vvv --fork-url MAINNET_RPC_URL --fork-block-number 15969633 --mc TestChocolate
    }

    function test_Dex1() public {
        // --------------- Add Liquidity ---------------
        // TODO: Add liquidity of 100,000 tokens and 100 ETH (1 token = 0.001 ETH)
        vm.startPrank(deployer);
        chocolate.approve(address(chocolate), INITIAL_LIQUIDITY);
        chocolate.addChocolateLiquidity{value: ETH_IN_LIQUIDITY}(INITIAL_LIQUIDITY);

        // TODO: Print the amount of LP tokens that the deployer owns
        console.log("Balance of LP tokens", pair.balanceOf(deployer));

        vm.stopPrank();

        // --------------- User Swaps ---------------
        // TODO: From user: Swap 10 ETH to Chocolate
        vm.startPrank(user);
        uint256 userBeforeChocoBalance = chocolate.balanceOf(user);
        chocolate.swapChocolates{value: TEN_ETH}(WETH_ADDRESS, TEN_ETH);

        // TODO: Make sure user received the chocolates (greater amount than before)
        uint256 userAfterChocoBalance = chocolate.balanceOf(user);
        assertGt(userAfterChocoBalance, userBeforeChocoBalance);

        // TODO: From user: Swap 100 Chocolates to ETH
        uint256 userWethBalance = weth.balanceOf(user);
        console.log("User Initial Weth Balance", userWethBalance);

        chocolate.approve(address(chocolate), HUNDRED_CHOCOLATES);
        chocolate.swapChocolates(address(chocolate), HUNDRED_CHOCOLATES);

        // TODO: Make sure user received the WETH (greater amount than before)
        userWethBalance = weth.balanceOf(user);
        console.log("User After swap Weth Balance", userWethBalance);
        assertGt(userWethBalance, 0);

        vm.stopPrank();

        // --------------- Remove Liquidity ---------------
        // TODO: Remove 50% of deployer's liquidity
        vm.startPrank(deployer);
        uint256 deployerChocolateBalance = chocolate.balanceOf(deployer);
        uint256 deployerWETHBalance = weth.balanceOf(deployer);
        uint256 deployerPairBalance = pair.balanceOf(deployer);

        uint256 lpTokensToRemove = deployerPairBalance / 2;

        pair.approve(address(chocolate), lpTokensToRemove);
        chocolate.removeChocolateLiquidity(lpTokensToRemove);

        // TODO: Make sure deployer owns 50% of the LP tokens (leftovers)
        assertEq(lpTokensToRemove, pair.balanceOf(deployer));

        // TODO: Make sure deployer got chocolate and weth back (greater amount than before)
        assertGt(chocolate.balanceOf(deployer), deployerChocolateBalance);
        assertGt(weth.balanceOf(deployer), deployerWETHBalance);
    }
}
