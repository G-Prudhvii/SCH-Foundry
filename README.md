Tasks:
--------
Create your contract under the ./contracts/erc20-1 folder:
1. Import and inherit from OpenZeppelin ERC20.sol contract
2. Choose your token NAME and SYMBOl
3. Set a contract owner upon deployment
4. Implement an external mint() function which can be called only from owner

Testing:
---------
1. Deploy your contract from the deployer account
2. Mint 100K tokens to yourself (Deployer)
3. Mint 5K tokens to each one of the users
4. Verify with a test that every user has the right amount of tokens
5. Transfer 100 tokens from User2 to User3
6. From User3: approve User1 to spend 1K tokens
7. Test that User1 has the right allowance that was given by User3
8. From User1: using transferFrom(), transfer 1K tokens from User3 to User1
9. Verify with a test that every user has the right amount of tokens
    
ERC20-2::
----------
forge test --fork-url $MAINNET_RPC_URL --fork-block-number 15969633 --mt testDepositsAndWithdraws