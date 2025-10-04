// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/17. Oracle Manipulation-2/Lendly.sol";
import "../../src/interfaces/IWETH9.sol";
import "../../src/17. Oracle Manipulation-2/AttackLendly.sol";

/**
 * @dev run: "forge test --mc TestOM2 --fork-url $MAINNET_RPC_URL --fork-block-number 15969633 -vvv"
 */
contract TestOM2 is Test {
    Lendly lendly;
    AttackLendly attackLendly;
    IWETH9 weth;
    IERC20 dai;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    address constant PAIR_ADDRESS = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11; // DAI/WETH
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address constant IMPERSONATED_ADDRESS = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Binance Hot Wallet

    uint256 constant WETH_LIQUIDITY = 180 ether; // 180 ETH
    uint256 constant DAI_LIQUIDITY = 270_000 ether; // 270k DAI

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */

        // Attacker starts with 1 ETH
        vm.deal(attacker, 1 ether);
        assertEq(attacker.balance, 1 ether);

        // Deploy Lendly with DAI/WETH contract
        vm.startPrank(deployer);
        lendly = new Lendly(PAIR_ADDRESS);

        // Load tokens contract
        weth = IWETH9(WETH_ADDRESS);
        dai = IERC20(DAI_ADDRESS);

        // Convert ETH to WETH
        vm.deal(deployer, WETH_LIQUIDITY);
        weth.deposit{value: WETH_LIQUIDITY}();
        assertEq(weth.balanceOf(deployer), WETH_LIQUIDITY);

        // Deposit WETH from Deployer to Lendly
        weth.approve(address(lendly), WETH_LIQUIDITY);
        lendly.deposit(address(weth), WETH_LIQUIDITY);

        // WETH deposit succeded
        assertEq(weth.balanceOf(address(lendly)), WETH_LIQUIDITY);
        assertEq(lendly.deposited(address(weth), deployer), WETH_LIQUIDITY);

        vm.stopPrank();

        // Deposit DAI on Lendly (from Binance Hot Wallet)
        vm.startPrank(IMPERSONATED_ADDRESS);
        dai.approve(address(lendly), DAI_LIQUIDITY);
        lendly.deposit(address(dai), DAI_LIQUIDITY);

        // DAI deposit succeded
        assertEq(dai.balanceOf(address(lendly)), DAI_LIQUIDITY);
        assertEq(lendly.deposited(address(dai), IMPERSONATED_ADDRESS), DAI_LIQUIDITY);

        // Didn't deposit WETH so can't borrow DAI
        vm.expectRevert();
        lendly.borrow(address(dai), DAI_LIQUIDITY);

        vm.stopPrank();

        // WETH depositor can borrow some DAI
        vm.prank(deployer);
        lendly.borrow(address(dai), 100 ether);
    }

    function testExploit() public {
        /**
         * CODE YOUR SOLUTION HERE
         */
        vm.startPrank(attacker);
        attackLendly = new AttackLendly(PAIR_ADDRESS, address(lendly));
        attackLendly.attack();

        vm.stopPrank();
        /**
         * SUCCESS CONDITIONS
         */

        // Protocol Liquidity
        console.log("Lendly DAI balance: ", dai.balanceOf(address(lendly)) / 1e18);
        console.log("Lendly WETH balance: ", weth.balanceOf(address(lendly)) / 1e18);

        console.log("Attacker DAI balance: ", dai.balanceOf(address(attacker)) / 1e18);
        console.log("Attacker WETH balance: ", weth.balanceOf(address(attacker)) / 1e18);

        // Pool liquidity should be at least -95%
        assertLt(dai.balanceOf(address(lendly)), DAI_LIQUIDITY * 5 / 100);
        assertLt(weth.balanceOf(address(lendly)), WETH_LIQUIDITY * 5 / 100);

        // Attacker stole the liquidity - at least +88%
        assertGt(dai.balanceOf(attacker), DAI_LIQUIDITY * 88 / 100);
        assertGt(weth.balanceOf(attacker), WETH_LIQUIDITY * 88 / 100);
    }
}
