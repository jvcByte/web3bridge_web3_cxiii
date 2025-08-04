// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Lib.sol";

// ============================================================================
// MAIN VOTING CONTRACT
// ============================================================================

/**
 * @title ModularVotingSystem
 * @dev Main contract that uses custom library for voting functionality
 */
contract ModularVotingSystem {
    using ElectionManager for ElectionManager.ElectionStorage;
    using CandidateManager for CandidateManager.CandidateStorage;
    using VoterManager for VoterManager.VoterStorage;
    using VotingValidator for uint256;
    using VotingValidator for address;
    using ResultsCalculator for uint256;
    
    // Storage structures
    ElectionManager.ElectionStorage private electionStorage;
    CandidateManager.CandidateStorage private candidateStorage;
    VoterManager.VoterStorage private voterStorage;
    
    address public electionAuthority;
    
    modifier onlyAuthority() {
        if (msg.sender != electionAuthority) {
            revert VotingErrors.UnauthorizedAccess();
        }
        _;
    }
    
    constructor() {
        electionAuthority = msg.sender;
    }
    
    // Election Management Functions
    function createElection(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        VotingTypes.ElectionType _electionType,
        uint256 _maxVotesPerVoter
    ) external onlyAuthority returns (uint256) {
        return electionStorage.createElection(
            _title,
            _description,
            _startTime,
            _endTime,
            _electionType,
            _maxVotesPerVoter
        );
    }
    
    function endElection(uint256 _electionId) external onlyAuthority {
        electionStorage.endElection(_electionId);
    }
    
    // Candidate Management Functions
    function registerCandidate(
        uint256 _electionId,
        string memory _name,
        string memory _party,
        string memory _manifestoHash
    ) external onlyAuthority returns (uint256) {
        return candidateStorage.registerCandidate(
            electionStorage.elections,
            _electionId,
            _name,
            _party,
            _manifestoHash
        );
    }
    
    // Voter Management Functions
    function registerVoter(
        uint256 _electionId,
        address _voterAddress,
        bytes32 _voterHash
    ) external onlyAuthority {
        voterStorage.registerVoter(
            electionStorage.elections,
            _electionId,
            _voterAddress,
            _voterHash
        );
    }
    
    function selfRegisterVoter(uint256 _electionId, bytes32 _voterHash) external {
        voterStorage.registerVoter(
            electionStorage.elections,
            _electionId,
            msg.sender,
            _voterHash
        );
    }
    
    // Voting Function
    function vote(uint256 _electionId, uint256 _candidateId) external {
        // Validate candidate
        _candidateId.validateCandidate(
            _electionId,
            candidateStorage.candidates,
            candidateStorage.candidateCount
        );
        
        // Cast vote
        voterStorage.castVote(
            electionStorage.elections,
            _electionId,
            msg.sender,
            _candidateId
        );
        
        // Update candidate vote count
        candidateStorage.incrementVoteCount(_electionId, _candidateId);
        
        // Update election total votes
        electionStorage.elections[_electionId].totalVotes++;
    }
    
    // Query Functions
    function getElection(uint256 _electionId) external view returns (VotingTypes.Election memory) {
        return electionStorage.getElection(_electionId);
    }
    
    function getCandidate(uint256 _electionId, uint256 _candidateId) 
        external 
        view 
        returns (VotingTypes.Candidate memory) 
    {
        return candidateStorage.getCandidate(_electionId, _candidateId);
    }
    
    function getVoter(uint256 _electionId, address _voterAddress) 
        external 
        view 
        returns (VotingTypes.Voter memory) 
    {
        return voterStorage.getVoter(_electionId, _voterAddress);
    }
    
    function getElectionResults(uint256 _electionId) 
        external 
        view 
        returns (VotingTypes.ElectionResults memory) 
    {
        return _electionId.calculateResults(
            electionStorage.elections,
            candidateStorage,
            voterStorage
        );
    }
    
    function transferAuthority(address _newAuthority) external onlyAuthority {
        _newAuthority.validateAddress();
        
        address oldAuthority = electionAuthority;
        electionAuthority = _newAuthority;
        
        emit VotingEvents.AuthorityTransferred(oldAuthority, _newAuthority);
    }
}