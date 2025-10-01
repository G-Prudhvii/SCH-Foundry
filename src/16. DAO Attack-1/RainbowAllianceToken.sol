// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RainbowAllianceToken is ERC20, Ownable {
    uint256 public lastProposalId;

    mapping(address => uint256) public getVotingPower;
    mapping(uint256 => Proposal) public getProposal;
    mapping(uint256 => mapping(address => bool)) public voted;

    struct Proposal {
        uint256 id;
        string description;
        uint256 yes;
        uint256 no;
    }

    constructor() ERC20("Rainbow Alliance", "RNB") {
        lastProposalId = 0;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        getVotingPower[_to] += _amount;
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
        getVotingPower[_from] -= _amount;
    }

    // @audit-issue Voting power is not transferred when someone transfers tokens

    function createProposal(string memory _description) external {
        require(getVotingPower[msg.sender] > 0, "no voting rights");
        require(bytes(_description).length != 0, "description is required");

        lastProposalId = lastProposalId + 1;

        getProposal[lastProposalId] =
            Proposal({id: lastProposalId, description: _description, yes: getVotingPower[msg.sender], no: 0});

        voted[lastProposalId][msg.sender] = true;
    }

    function vote(uint256 _id, bool _decision) external {
        require(getVotingPower[msg.sender] > 0, "no voting rights");
        require(!voted[_id][msg.sender], "already voted");
        Proposal storage proposal = getProposal[_id];

        require(_id > 0 && _id <= lastProposalId, "proposal doesn't exist");

        if (_decision) {
            proposal.yes += getVotingPower[msg.sender];
        } else {
            proposal.no += getVotingPower[msg.sender];
        }

        getProposal[proposal.id] = proposal;
        voted[_id][msg.sender] = true;
    }
}
