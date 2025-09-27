# Sensitive On-Chain Data Exercise 3

## Intro

Cryptic Raffle is a new on-chain lottery game.

The raffle contract is deployed on Sepolia testnet, and its address is:

`0x6c20a5b55613c1f1ccc3102ec44288b15c6d2ae0`

Anyone can participate and earn ETH.

The game is initially deployed with 0.1 ETH.

### Rules
* The manager of the game (contract owner), creates new raffles every once in a while
* A raffle consists of 3 numbers between 0-255
* In order to win the raffle, the player needs to guess all 3 numbers in the right order.
* Participation cost 0.01 ETH (which accumulates in the smart contract)
* The winner takes all the pot of the current raffle

There are some addicted gamblers who are trying different strategies to win the raffle.

Lucky you, you can beat them all thanks to your smart contract hacking skills.

You're (your Attacker account) broke and you only own 0.1 ETH.

Your goal is to win the current raffle round and claim all the pot.

**Note: This exercise is executed on an Sepolia testnet local fork block number `7483527`. Everything is already configured in the `hardhat.config.js` file.**

**Note: In this exercise you don't have access to the source code of the CrypticRaffle.sol smart contract.**

## Setup
Update your `.env` file and add the SEPOLIA Infura RPC url:
```
Sepolia = '<your-sepolia-infura-rpc-url>'
```

## Accounts
* 0 - AddictedGambler1
* 1 - AddictedGambler2
* 2 - Attacker (You)

<div style="page-break-after: always;"></div>

## Tasks

### Task 1
Win the raffle and claim all the ETH that is currently in the contract's pot.

### Bonus
Find another way to find the winnig numbers :)

## Useful Links
* [Sepolia EtherScan](https://sepolia.etherscan.io/)
* [Cast Commands](https://book.getfoundry.sh/reference/cast/)

## Sepolia Public RPC Nodes
```
https://sepolia.drpc.org
https://ethereum-sepolia.rpc.subquery.network/public
https://eth-sepolia.public.blastapi.io
https://1rpc.io/sepolia
https://gateway.tenderly.co/public/sepolia
https://ethereum-sepolia-rpc.publicnode.com
```