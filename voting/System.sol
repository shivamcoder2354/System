// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VotingSystem {
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool exists;
    }
    
    address public owner;
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event VoteCast(address voter, uint256 proposalId, bool vote);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Function 1: Create a new proposal (only owner)
    function createProposal(string memory _description, uint256 _durationInDays) 
        external 
        onlyOwner 
    {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_durationInDays > 0 && _durationInDays <= 30, "Duration must be 1-30 days");
        
        proposalCounter++;
        uint256 endTime = block.timestamp + (_durationInDays * 1 days);
        
        proposals[proposalCounter] = Proposal({
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            endTime: endTime,
            exists: true
        });
        
        emit ProposalCreated(proposalCounter, _description, endTime);
    }
    
    // Function 2: Cast vote on a proposal
    function vote(uint256 _proposalId, bool _vote) 
        external 
        proposalExists(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");
        
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        
        emit VoteCast(msg.sender, _proposalId, _vote);
    }
    
    // Function 3: Get proposal details
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            string memory description,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 endTime,
            bool isActive
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        bool active = block.timestamp < proposal.endTime;
        
        return (
            proposal.description,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.endTime,
            active
        );
    }
    
    // Function 4: Get voting results
    function getResults(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVotes,
            string memory result
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        uint256 total = proposal.yesVotes + proposal.noVotes;
        string memory outcome;
        
        if (block.timestamp < proposal.endTime) {
            outcome = "Voting in progress";
        } else if (proposal.yesVotes > proposal.noVotes) {
            outcome = "Proposal passed";
        } else if (proposal.noVotes > proposal.yesVotes) {
            outcome = "Proposal rejected";
        } else {
            outcome = "Tie";
        }
        
        return (proposal.yesVotes, proposal.noVotes, total, outcome);
    }
    
    // Function 5: Check if user has voted
    function checkVotingStatus(uint256 _proposalId, address _voter) 
        external 
        view 
        proposalExists(_proposalId)
        returns (bool) 
    {
        return hasVoted[_proposalId][_voter];
    }
}
