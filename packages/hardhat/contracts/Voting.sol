//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { LeanIMT, LeanIMTData } from "@zk-kit/lean-imt.sol/LeanIMT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVerifier } from "./Verifier.sol";

contract Voting is Ownable {
    using LeanIMT for LeanIMTData;

    error Voting__CommitmentAlreadyAdded(uint256 commitment);
    error Voting__NullifierHashAlreadyUsed(bytes32 nullifierHash);
    error Voting__InvalidProof();
    error Voting__NotAllowedToVote();
    error Voting__EmptyTree();
    error Voting__InvalidRoot();

    string private s_question;
    mapping(address => bool) private s_voters;
    uint256 private s_yesVotes;
    uint256 private s_noVotes;
    mapping(address => bool) private s_hasRegistered;
    mapping(uint256 => bool) private s_commitments;
    LeanIMTData private s_tree;
    mapping(bytes32 => bool) private s_nullifierHashes;
    IVerifier private s_verifier;

    event VoterAdded(address indexed voter);
    event NewLeaf(uint256 index, uint256 value);
    event VoteCast(bytes32 indexed nullifierHash, address indexed voter, bool vote, uint256 timestamp, uint256 totalYes, uint256 totalNo);

    constructor(address _owner, address _verifier, string memory _question) Ownable(_owner) {
        s_question = _question;
        s_verifier = IVerifier(_verifier);
    }

    function addVoters(address[] calldata voters, bool[] calldata statuses) public onlyOwner {
        require(voters.length == statuses.length, "Voters and statuses length mismatch");
        for (uint256 i = 0; i < voters.length; i++) {
            s_voters[voters[i]] = statuses[i];
            emit VoterAdded(voters[i]);
        }
    }

    function register(uint256 _commitment) public {
        if (!s_voters[msg.sender] || s_hasRegistered[msg.sender]) revert Voting__NotAllowedToVote();
        if (s_commitments[_commitment]) revert Voting__CommitmentAlreadyAdded(_commitment);
        uint256 index = s_tree.size;
        s_tree.insert(_commitment);
        s_hasRegistered[msg.sender] = true;
        s_commitments[_commitment] = true;
        emit NewLeaf(index, _commitment);
    }

    function vote(bytes memory _proof, bytes32 _nullifierHash, bytes32 _root, bytes32 _vote, bytes32 _depth) public {
        if (_root == bytes32(0)) revert Voting__EmptyTree();
        if (_root != bytes32(s_tree.root())) revert Voting__InvalidRoot();
        if (s_nullifierHashes[_nullifierHash]) revert Voting__NullifierHashAlreadyUsed(_nullifierHash);
        bytes32[] memory publicInputs = new bytes32[](4);
        publicInputs[0] = _nullifierHash;
        publicInputs[1] = _root;
        publicInputs[2] = _vote;
        publicInputs[3] = _depth;
        if (!s_verifier.verify(_proof, publicInputs)) revert Voting__InvalidProof();
        s_nullifierHashes[_nullifierHash] = true;
        bool isYes = _vote == bytes32(uint256(1));
        if (isYes) s_yesVotes++; else s_noVotes++;
        emit VoteCast(_nullifierHash, msg.sender, isYes, block.timestamp, s_yesVotes, s_noVotes);
    }

    function getVotingData() public view returns (string memory question, address contractOwner, uint256 yesVotes, uint256 noVotes, uint256 size, uint256 depth, uint256 root) {
        return (s_question, owner(), s_yesVotes, s_noVotes, s_tree.size, s_tree.depth, s_tree.root());
    }

    function getVoterData(address _voter) public view returns (bool voter, bool registered) {
        return (s_voters[_voter], s_hasRegistered[_voter]);
    }
}