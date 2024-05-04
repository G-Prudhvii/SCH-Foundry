// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SCHToken is ERC20 {
    address private _owner;

    constructor() ERC20("SCHToken", "SCH") {
        _mint(msg.sender, 100000);
        _owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == _owner, "Not Owner");
        _mint(to, amount);
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}
