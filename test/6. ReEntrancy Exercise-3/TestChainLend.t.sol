// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ChainLend} from "../../src/6. ReEntrancy Exercise-3/ChainLend.sol";
import {AttackChainLend} from "../../src/6. ReEntrancy Exercise-3/AttackChainLend.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestChainLend is Test {
    ChainLend lend;
    AttackChainLend attackContract;
    IERC20 imBTC;
    IERC20 usdc;

    address imBTC_ADDRESS = 0x3212b29E33587A00FB1C83346f5dBFA69A458923;
    address USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address imBTC_WHALE = 0xFEa4224Da399F672eB21a9F3F7324cEF1d7a965C;
    address USDC_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant USDC_IN_CHAINLEND = 1000000 * 1e6;
    uint256 constant ONE_IMBTC = 1 * 1e8;

    function setUp() public {
        // Fund deployer & attacker with 100 ETH
        vm.deal(deployer, 100 ether);
        vm.deal(attacker, 100 ether);

        imBTC = IERC20(imBTC_ADDRESS);
        usdc = IERC20(USDC_ADDRESS);

        vm.prank(deployer);
        lend = new ChainLend(imBTC_ADDRESS, USDC_ADDRESS);

        // Impersonate USDC Whale and send 1M USDC to ChainLend
        vm.prank(USDC_WHALE);
        usdc.transfer(address(lend), USDC_IN_CHAINLEND);

        assertEq(usdc.balanceOf(address(lend)), USDC_IN_CHAINLEND);

        // Impersonate imBTC Whale and send 1 imBTC to attacker
        vm.prank(imBTC_WHALE);
        imBTC.transfer(attacker, ONE_IMBTC);

        assertEq(imBTC.balanceOf(attacker), ONE_IMBTC);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        attackContract = new AttackChainLend(imBTC_ADDRESS, USDC_ADDRESS, address(lend));
        imBTC.transfer(address(attackContract), ONE_IMBTC);

        assertEq(imBTC.balanceOf(address(attackContract)), ONE_IMBTC);

        attackContract.exploit();
        vm.stopPrank();

        // Attacker drained all chainlend USDC balance
        assertEq(usdc.balanceOf(attacker), USDC_IN_CHAINLEND);
        assertEq(imBTC.balanceOf(attacker), ONE_IMBTC);
    }
}
