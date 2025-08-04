// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ============================================================================
// VOTING SYSTEM LIBRARIES
// ============================================================================

/**
 * @title VotingTypes
 * @dev Library containing all data structures used across the voting system
 */
library VotingTypes {
    struct Candidate {
        uint256 id;
        string name;
        string party;
        string manifestoHash; // IPFS hash for candidate manifesto
        uint256 voteCount;
        bool isActive;
        uint256 registrationTime;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
        uint256 registrationTime;
        bytes32 voterHash; // Hash of voter credentials for privacy
    }
    
    struct Election {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 totalVotes;
        uint256 maxVotesPerVoter;
        ElectionType electionType;
    }
    
    enum ElectionType {
        SINGLE_CHOICE,
        MULTIPLE_CHOICE,
        RANKED_CHOICE
    }
    
    struct ElectionResults {
        uint256 electionId;
        uint256 totalVotes;
        uint256 totalRegisteredVoters;
        uint256[] candidateIds;
        uint256[] voteCounts;
        address winner;
        bool isFinalized;
    }
}

/**
 * @title VotingErrors
 * @dev Library containing all custom errors used across the voting system
 */
library VotingErrors {
    error UnauthorizedAccess();
    error VoterNotRegistered();
    error VoterAlreadyVoted();
    error ElectionNotActive();
    error ElectionNotStarted();
    error ElectionEnded();
    error InvalidCandidateId();
    error CandidateNotActive();
    error InvalidStartTime();
    error InvalidEndTime();
    error ElectionDoesNotExist();
    error CannotRegisterAfterStart();
    error VoterAlreadyRegistered();
    error RegistrationClosed();
    error ElectionEndTimeNotReached();
    error InvalidAddress();
    error InvalidElectionType();
    error MaxVotesExceeded();
    error ElectionAlreadyFinalized();
    error InsufficientCandidates();
}

/**
 * @title VotingEvents
 * @dev Library containing all events used across the voting system
 */
library VotingEvents {
    event ElectionCreated(uint256 indexed electionId, string title, uint256 startTime, uint256 endTime);
    event CandidateRegistered(uint256 indexed electionId, uint256 candidateId, string name, string party);
    event VoterRegistered(uint256 indexed electionId, address indexed voter, bytes32 voterHash);
    event VoteCast(uint256 indexed electionId, address indexed voter, uint256 candidateId);
    event ElectionEnded(uint256 indexed electionId, uint256 totalVotes);
    event ElectionFinalized(uint256 indexed electionId, address winner);
    event AuthorityTransferred(address indexed oldAuthority, address indexed newAuthority);
}

/**
 * @title ElectionManager
 * @dev Library for managing election lifecycle and administration
 */
library ElectionManager {
    using VotingValidator for uint256;
    
    struct ElectionStorage {
        mapping(uint256 => VotingTypes.Election) elections;
        mapping(uint256 => uint256) candidateCount;
        uint256 currentElectionId;
    }
    
    function createElection(
        ElectionStorage storage self,
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        VotingTypes.ElectionType _electionType,
        uint256 _maxVotesPerVoter
    ) external returns (uint256) {
        if (_startTime <= block.timestamp) {
            revert VotingErrors.InvalidStartTime();
        }
        if (_endTime <= _startTime) {
            revert VotingErrors.InvalidEndTime();
        }
        
        self.currentElectionId++;
        
        self.elections[self.currentElectionId] = VotingTypes.Election({
            id: self.currentElectionId,
            title: _title,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            isActive: true,
            totalVotes: 0,
            maxVotesPerVoter: _maxVotesPerVoter,
            electionType: _electionType
        });
        
        emit VotingEvents.ElectionCreated(self.currentElectionId, _title, _startTime, _endTime);
        return self.currentElectionId;
    }
    
    function endElection(
        ElectionStorage storage self,
        uint256 _electionId
    ) external {
        _electionId.validateElectionExists(self.elections);
        
        if (!self.elections[_electionId].isActive) {
            revert VotingErrors.ElectionNotActive();
        }
        if (block.timestamp <= self.elections[_electionId].endTime) {
            revert VotingErrors.ElectionEndTimeNotReached();
        }
        
        self.elections[_electionId].isActive = false;
        
        emit VotingEvents.ElectionEnded(_electionId, self.elections[_electionId].totalVotes);
    }
    
    function getElection(
        ElectionStorage storage self,
        uint256 _electionId
    ) external view returns (VotingTypes.Election memory) {
        return self.elections[_electionId];
    }
}

/**
 * @title CandidateManager
 * @dev Library for managing candidate registration and information
 */
library CandidateManager {
    using VotingValidator for uint256;
    
    struct CandidateStorage {
        mapping(uint256 => mapping(uint256 => VotingTypes.Candidate)) candidates;
        mapping(uint256 => uint256) candidateCount;
    }
    
    function registerCandidate(
        CandidateStorage storage self,
        mapping(uint256 => VotingTypes.Election) storage elections,
        uint256 _electionId,
        string memory _name,
        string memory _party,
        string memory _manifestoHash
    ) external returns (uint256) {
        _electionId.validateElectionExists(elections);
        
        if (!elections[_electionId].isActive) {
            revert VotingErrors.ElectionDoesNotExist();
        }
        if (block.timestamp >= elections[_electionId].startTime) {
            revert VotingErrors.CannotRegisterAfterStart();
        }
        
        self.candidateCount[_electionId]++;
        uint256 candidateId = self.candidateCount[_electionId];
        
        self.candidates[_electionId][candidateId] = VotingTypes.Candidate({
            id: candidateId,
            name: _name,
            party: _party,
            manifestoHash: _manifestoHash,
            voteCount: 0,
            isActive: true,
            registrationTime: block.timestamp
        });
        
        emit VotingEvents.CandidateRegistered(_electionId, candidateId, _name, _party);
        return candidateId;
    }
    
    function getCandidate(
        CandidateStorage storage self,
        uint256 _electionId,
        uint256 _candidateId
    ) external view returns (VotingTypes.Candidate memory) {
        return self.candidates[_electionId][_candidateId];
    }
    
    function getCandidateCount(
        CandidateStorage storage self,
        uint256 _electionId
    ) external view returns (uint256) {
        return self.candidateCount[_electionId];
    }
    
    function incrementVoteCount(
        CandidateStorage storage self,
        uint256 _electionId,
        uint256 _candidateId
    ) external {
        self.candidates[_electionId][_candidateId].voteCount++;
    }
}

/**
 * @title VoterManager
 * @dev Library for managing voter registration and voting process
 */
library VoterManager {
    using VotingValidator for uint256;
    using VotingValidator for address;
    
    struct VoterStorage {
        mapping(uint256 => mapping(address => VotingTypes.Voter)) voters;
        mapping(uint256 => uint256) registeredVoterCount;
    }
    
    function registerVoter(
        VoterStorage storage self,
        mapping(uint256 => VotingTypes.Election) storage elections,
        uint256 _electionId,
        address _voterAddress,
        bytes32 _voterHash
    ) external {
        _electionId.validateElectionExists(elections);
        _voterAddress.validateAddress();
        
        if (!elections[_electionId].isActive) {
            revert VotingErrors.ElectionDoesNotExist();
        }
        if (self.voters[_electionId][_voterAddress].isRegistered) {
            revert VotingErrors.VoterAlreadyRegistered();
        }
        
        self.voters[_electionId][_voterAddress] = VotingTypes.Voter({
            isRegistered: true,
            hasVoted: false,
            votedCandidateId: 0,
            registrationTime: block.timestamp,
            voterHash: _voterHash
        });
        
        self.registeredVoterCount[_electionId]++;
        
        emit VotingEvents.VoterRegistered(_electionId, _voterAddress, _voterHash);
    }
    
    function castVote(
        VoterStorage storage self,
        mapping(uint256 => VotingTypes.Election) storage elections,
        uint256 _electionId,
        address _voter,
        uint256 _candidateId
    ) external {
        _electionId.validateElectionActive(elections);
        _voter.validateRegisteredVoter(self.voters, _electionId);
        _voter.validateHasNotVoted(self.voters, _electionId);
        
        self.voters[_electionId][_voter].hasVoted = true;
        self.voters[_electionId][_voter].votedCandidateId = _candidateId;
        
        emit VotingEvents.VoteCast(_electionId, _voter, _candidateId);
    }
    
    function getVoter(
        VoterStorage storage self,
        uint256 _electionId,
        address _voterAddress
    ) external view returns (VotingTypes.Voter memory) {
        return self.voters[_electionId][_voterAddress];
    }
    
    function getRegisteredVoterCount(
        VoterStorage storage self,
        uint256 _electionId
    ) external view returns (uint256) {
        return self.registeredVoterCount[_electionId];
    }
}

/**
 * @title VotingValidator
 * @dev Library containing validation functions used across the voting system
 */
library VotingValidator {
    function validateAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert VotingErrors.InvalidAddress();
        }
    }
    
    function validateElectionExists(
        uint256 _electionId,
        mapping(uint256 => VotingTypes.Election) storage elections
    ) internal view {
        if (_electionId == 0 || !elections[_electionId].isActive) {
            revert VotingErrors.ElectionDoesNotExist();
        }
    }
    
    function validateElectionActive(
        uint256 _electionId,
        mapping(uint256 => VotingTypes.Election) storage elections
    ) internal view {
        validateElectionExists(_electionId, elections);
        
        if (block.timestamp < elections[_electionId].startTime) {
            revert VotingErrors.ElectionNotStarted();
        }
        if (block.timestamp > elections[_electionId].endTime) {
            revert VotingErrors.ElectionEnded();
        }
    }
    
    function validateRegisteredVoter(
        address _voter,
        mapping(uint256 => mapping(address => VotingTypes.Voter)) storage voters,
        uint256 _electionId
    ) internal view {
        if (!voters[_electionId][_voter].isRegistered) {
            revert VotingErrors.VoterNotRegistered();
        }
    }
    
    function validateHasNotVoted(
        address _voter,
        mapping(uint256 => mapping(address => VotingTypes.Voter)) storage voters,
        uint256 _electionId
    ) internal view {
        if (voters[_electionId][_voter].hasVoted) {
            revert VotingErrors.VoterAlreadyVoted();
        }
    }
    
    function validateCandidate(
        uint256 _electionId,
        uint256 _candidateId,
        mapping(uint256 => mapping(uint256 => VotingTypes.Candidate)) storage candidates,
        mapping(uint256 => uint256) storage candidateCount
    ) internal view {
        if (_candidateId == 0 || _candidateId > candidateCount[_electionId]) {
            revert VotingErrors.InvalidCandidateId();
        }
        if (!candidates[_electionId][_candidateId].isActive) {
            revert VotingErrors.CandidateNotActive();
        }
    }
}

/**
 * @title ResultsCalculator
 * @dev Library for calculating and managing election results
 */
library ResultsCalculator {
    using CandidateManager for CandidateManager.CandidateStorage;
    using VoterManager for VoterManager.VoterStorage;
    
    function calculateResults(
        uint256 _electionId,
        mapping(uint256 => VotingTypes.Election) storage elections,
        CandidateManager.CandidateStorage storage candidates,
        VoterManager.VoterStorage storage voters
    ) external view returns (VotingTypes.ElectionResults memory) {
        VotingTypes.Election memory election = elections[_electionId];
        uint256 candidateCount = candidates.getCandidateCount(_electionId);
        
        uint256[] memory candidateIds = new uint256[](candidateCount);
        uint256[] memory voteCounts = new uint256[](candidateCount);
        
        uint256 maxVotes = 0;
        uint256 winnerId = 0;
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            VotingTypes.Candidate memory candidate = candidates.getCandidate(_electionId, i);
            candidateIds[i-1] = candidate.id;
            voteCounts[i-1] = candidate.voteCount;
            
            if (candidate.voteCount > maxVotes) {
                maxVotes = candidate.voteCount;
                winnerId = candidate.id;
            }
        }
        
        return VotingTypes.ElectionResults({
            electionId: _electionId,
            totalVotes: election.totalVotes,
            totalRegisteredVoters: voters.getRegisteredVoterCount(_electionId),
            candidateIds: candidateIds,
            voteCounts: voteCounts,
            winner: address(uint160(winnerId)), // Simplified - in real implementation, map to candidate address
            isFinalized: !election.isActive
        });
    }
    
    function getWinner(
        uint256 _electionId,
        CandidateManager.CandidateStorage storage candidates
    ) external view returns (uint256 winnerId, uint256 maxVotes) {
        uint256 candidateCount = candidates.getCandidateCount(_electionId);
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            VotingTypes.Candidate memory candidate = candidates.getCandidate(_electionId, i);
            if (candidate.voteCount > maxVotes) {
                maxVotes = candidate.voteCount;
                winnerId = candidate.id;
            }
        }
    }
}
