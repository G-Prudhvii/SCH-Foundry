// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/16. DAO Attack-3/DAOToken.sol";
import "../../src/16. DAO Attack-3/Treasury.sol";
import "../../src/16. DAO Attack-3/Governance.sol";
import "../../src/16. DAO Attack-3/LendingPool.sol";
import "../../src/16. DAO Attack-3/AttackDAO.sol";

contract TestDAO3 is Test {
    DAOToken token;
    Treasury treasury;
    Governance governance;
    LendingPool lendingPool;
    AttackDAO attackerContract;

    address deployer = makeAddr("deployer");
    address member1 = makeAddr("member1");
    address member2 = makeAddr("member2");
    address attacker = makeAddr("attacker");

    address startup = makeAddr("startup"); // Attacker's controlled address

    uint256 constant DEPLOYER_TOKENS = 2_500_000e18; // 2.5 million
    uint256 constant MEMBER1_TOKENS = 500_000e18; // 0.5 million
    uint256 constant MEMBER2_TOKENS = 1_000_000e18; // 1 million
    uint256 constant TOKENS_IN_POOL = 2_000_000e18; // 2 million

    // Treasury ETH
    uint256 constant ETH_IN_TREASURY = 1500 ether;

    uint256 attackerInitialEthBalance;

    function setUp() public {
        attackerInitialEthBalance = attacker.balance;

        // Deploy and Setup contracts
        vm.startPrank(deployer);
        token = new DAOToken();
        treasury = new Treasury();
        governance = new Governance(address(token), address(treasury));
        treasury.setGovernance(address(governance));
        lendingPool = new LendingPool(address(token));

        // Send ETH to Treasury
        vm.deal(address(treasury), ETH_IN_TREASURY);
        assertEq(address(treasury).balance, ETH_IN_TREASURY);

        // Mint tokens to Deployer, Members and the Pool
        token.mint(deployer, DEPLOYER_TOKENS);
        token.mint(member1, MEMBER1_TOKENS);
        token.mint(member2, MEMBER2_TOKENS);
        token.mint(address(lendingPool), TOKENS_IN_POOL);
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        // Deploy attacker contract
        attackerContract = new AttackDAO(address(token), address(governance), address(lendingPool), address(treasury));
        attackerContract.executeAttack();
        vm.stopPrank();

        // Attacker has taken all ETH from the treasury
        assertGt(attacker.balance, attackerInitialEthBalance + ETH_IN_TREASURY - 0.2 ether);
        assertEq(address(treasury).balance, 0);
    }
}
