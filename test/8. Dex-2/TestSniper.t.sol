// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../../src/8. Dex-2/Snipe.sol";
// import "../../src/Interfaces/IUniswapV2.sol";
import "../../src/Interfaces/IWETH9.sol";
import "../../src/Utils/DummyERC20.sol";

contract TestSniper is Test {
    address liquidityAdder = makeAddr("liquidityAdder");
    address user = makeAddr("user");

    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAPV2_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNISWAPV2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint128 ETH_BALANCE = 300 ether;

    uint128 INITIAL_MINT = 80000 ether;
    uint128 INITIAL_LIQUIDITY = 10000 ether;
    uint128 ETH_IN_LIQUIDITY = 50 ether;

    uint128 constant ETH_TO_INVEST = 35 ether;
    uint128 constant MIN_AMOUNT_OUT = 1750 ether;

    IUniswapV2Router02 router;
    Sniper sniper;
    DummyERC20 preciousToken;
    IWETH9 weth = IWETH9(WETH_ADDRESS);

    function setUp() public {
        // vm.label(WETH_ADDRESS, "WETH");
        // vm.label(UNISWAPV2_ROUTER_ADDRESS, "UniswapV2Router02");
        // vm.label(UNISWAPV2_FACTORY_ADDRESS, "UniswapV2Factory");
        // Set ETH balance
        vm.deal(liquidityAdder, ETH_BALANCE);
        vm.deal(user, ETH_BALANCE);

        // Deploy token
        vm.startPrank(liquidityAdder);
        preciousToken = new DummyERC20("PreciousToken", "PRECIOUS", INITIAL_MINT);

        // Load Uniswap Router contract
        router = IUniswapV2Router02(UNISWAPV2_ROUTER_ADDRESS);

        // Set the liquidity add operation deadline
        uint256 deadline = block.timestamp + 10000;

        // Deposit to WETH & approve router to spend tokens
        weth.deposit{value: ETH_IN_LIQUIDITY}();
        weth.approve(UNISWAPV2_ROUTER_ADDRESS, ETH_IN_LIQUIDITY);
        preciousToken.approve(UNISWAPV2_ROUTER_ADDRESS, INITIAL_LIQUIDITY);

        // Add the liquidity 10,000 PRECIOUS & 50 WETH
        router.addLiquidity(
            address(preciousToken),
            WETH_ADDRESS,
            INITIAL_LIQUIDITY,
            ETH_IN_LIQUIDITY,
            INITIAL_LIQUIDITY,
            ETH_IN_LIQUIDITY,
            liquidityAdder,
            deadline
        );

        vm.stopPrank();
    }

    function testAttack() public {
        vm.startPrank(user);
        // TODO: Deploy your smart contract to `this.sniper`
        sniper = new Sniper(UNISWAPV2_FACTORY_ADDRESS);

        // TODO: Sniper the tokens using your snipe function
        // NOTE: Your rich friend is willing to invest 35 ETH in the project, and is willing to pay 0.02 WETH per PRECIOUS
        // Which is 4x time more expensive than the initial liquidity price.
        // You should retry 3 times to buy the token.
        // Make sure to deposit to WETH and send the tokens to the sniper contract in advance

        weth.deposit{value: ETH_TO_INVEST}();
        weth.transfer(address(sniper), weth.balanceOf(user));

        sniper.snipe(WETH_ADDRESS, address(preciousToken), ETH_TO_INVEST, MIN_AMOUNT_OUT, 3);

        /**
         * SUCCESS CONDITIONS
         */

        // Bot was able to snipe at least 4,000 precious tokens
        // Bought at a price of ~0.00875 ETH per token (35 / 4000)
        uint256 preciousBalance = preciousToken.balanceOf(user);
        console.log("Sniped Balance: ", preciousBalance);
        assertEq(preciousBalance > 4000 ether, true);
    }
}
