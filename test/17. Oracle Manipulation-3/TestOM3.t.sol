// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/17. Oracle Manipulation-3/LendLand.sol";
import "../../src/interfaces/IWETH9.sol";
import "../../src/17. Oracle Manipulation-3/AttackLendLand.sol";

/**
 * @dev run: "forge test --mc TestOM3 --fork-url $MAINNET_RPC_URL --fork-block-number 15969633 -vvv"
 */
contract TestOM3 is Test {
    LendLand lendLand;
    AttackLendLand attackLendLand;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    address constant PAIR_ADDRESS = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11; // DAI/WETH
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address constant IMPERSONATED_ADDRESS = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Binance Hot Wallet

    uint256 constant WETH_LIQUIDITY = 1000 ether; // 1000 ETH
    uint256 constant DAI_LIQUIDITY = 1_500_000 ether; // 1.5M DAI

    // Attacker Added Constants
    address constant UNISWAPV2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant AAVE_POOL_ADDRESS = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant AAVE_AWETH_ADDRESS = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address constant AAVE_ADAI_ADDRESS = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    IWETH9 weth;
    IERC20 dai;

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */

        // Attacker starts with 1 ETH
        vm.deal(attacker, 1 ether);
        assertEq(attacker.balance, 1 ether);

        // Deploy LendLand with DAI/WETH contract
        vm.deal(deployer, WETH_LIQUIDITY);
        vm.startPrank(deployer);
        lendLand = new LendLand(PAIR_ADDRESS);

        // Load token contract
        weth = IWETH9(WETH_ADDRESS);
        dai = IERC20(DAI_ADDRESS);

        // Convert ETH to WETH
        weth.deposit{value: WETH_LIQUIDITY}();
        assertEq(weth.balanceOf(address(deployer)), WETH_LIQUIDITY);

        // Deposit WETH from Deployer to LendLand
        weth.approve(address(lendLand), WETH_LIQUIDITY);
        lendLand.deposit(address(weth), WETH_LIQUIDITY);

        // WETH deposit succeded
        assertEq(weth.balanceOf(address(lendLand)), WETH_LIQUIDITY);
        assertEq(lendLand.deposited(address(weth), deployer), WETH_LIQUIDITY);

        vm.stopPrank();

        // Deposit DAI on LendLand (from Binance hot wallet)
        vm.startPrank(IMPERSONATED_ADDRESS);
        dai.approve(address(lendLand), DAI_LIQUIDITY);
        lendLand.deposit(address(dai), DAI_LIQUIDITY);

        // DAI deposit succeded
        assertEq(dai.balanceOf(address(lendLand)), DAI_LIQUIDITY);
        assertEq(lendLand.deposited(address(dai), IMPERSONATED_ADDRESS), DAI_LIQUIDITY);

        // Didn't deposit WETH so can't borrow DAI
        vm.expectRevert();
        lendLand.borrow(address(dai), DAI_LIQUIDITY);

        vm.stopPrank();

        // WETH depositor can borrow some DAI
        vm.prank(deployer);
        lendLand.borrow(address(dai), 100 ether);
    }

    function testExploit() public {
        /**
         * CODE YOUR SOLUTION HERE
         */
        vm.startPrank(attacker);
        attackLendLand = new AttackLendLand(
            PAIR_ADDRESS,
            UNISWAPV2_ROUTER_ADDRESS,
            address(lendLand),
            AAVE_POOL_ADDRESS,
            AAVE_AWETH_ADDRESS,
            AAVE_ADAI_ADDRESS
        );

        attackLendLand.attack();

        /**
         * SUCCESS CONDITIONS
         */

        // Protocol Liquidity
        console.log("LendLand DAI Balance: ", dai.balanceOf(address(lendLand)) / 1e18);
        console.log("LendLand WETH Balance: ", weth.balanceOf(address(lendLand)) / 1e18);

        console.log("Attacker DAI Balance: ", dai.balanceOf(address(attacker)) / 1e18);
        console.log("Attacker WETH Balance: ", weth.balanceOf(address(attacker)) / 1e18);

        // Pool liquidity should be at least -98%
        assertLt(dai.balanceOf(address(lendLand)), DAI_LIQUIDITY * 2 / 100);
        assertLt(weth.balanceOf(address(lendLand)), WETH_LIQUIDITY * 2 / 100);

        // Attacker stole the liquidity at least +92%
        assertGt(dai.balanceOf(attacker), DAI_LIQUIDITY * 92 / 100);
        assertGt(weth.balanceOf(attacker), WETH_LIQUIDITY * 92 / 100);
    }
}
