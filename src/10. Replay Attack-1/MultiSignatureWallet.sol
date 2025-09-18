// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Signature.sol";

contract MultiSignatureWallet {
    using Address for address payable;

    address[2] public signatories;

    constructor(address[2] memory _signatories) {
        signatories = _signatories;
    }

    function transfer(address to, uint256 amount, Signature[2] memory signatures) external {
        // Authenticity check
        require(_verifySignature(to, amount, signatures[0]) == signatories[0], "Access restricted");
        require(_verifySignature(to, amount, signatures[1]) == signatories[1], "Access restricted");

        payable(to).sendValue(amount);
    }

    function _verifySignature(address to, uint256 amount, Signature memory signature)
        internal
        pure
        returns (address signer)
    {
        // 52 = message byte length
        string memory header = "\x19Ethereum Signed Message:\n52";

        bytes32 messageHash = keccak256(abi.encodePacked(header, to, amount));

        // Perform the elliptic curve recover operation
        return ecrecover(messageHash, signature.v, signature.r, signature.s);
    }

    receive() external payable {}
}
