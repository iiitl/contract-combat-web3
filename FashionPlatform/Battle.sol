// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Battle is ERC721URIStorage, Ownable(msg.sender) {
    uint256 public battleCounter;
    uint256 public tokenCounter;

    struct Design {
        address creator;
        string designURI;
        uint256 votes;
    }

    struct Battle {
        uint256 battleId;
        string battleURI;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        mapping(uint256 => Design) designs;
        uint256 designCount;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Battle) public battles;

    event BattleCreated(uint256 indexed battleId, uint256 startTime, uint256 endTime, string battleURI);
    event DesignSubmitted(uint256 indexed battleId, uint256 designId, address creator, string designURI);
    event Voted(uint256 indexed battleId, uint256 designId, address voter);
    event WinnerDeclared(uint256 indexed battleId, uint256 winningDesignId, address winner);

    constructor() ERC721("NFTBattle", "NFTB") {}

    function createBattle(uint256 duration, string memory _battleURI) external onlyOwner {
        battleCounter++;
        uint256 battleId = battleCounter;

        battles[battleId].battleId = battleId;
        battles[battleId].startTime = block.timestamp;
        battles[battleId].endTime = block.timestamp + duration;
        battles[battleId].ended = false;
        battles[battleId].battleURI = _battleURI;

        emit BattleCreated(battleId, block.timestamp, block.timestamp + duration, _battleURI);
    }

    function viewDesigns(uint256 battleId) external view returns (Design[] memory) {
        require(battles[battleId].startTime != 0, "Battle does not exist");

        Battle storage battle = battles[battleId];
        uint256 designCount = battle.designCount;

        Design[] memory designs = new Design[](designCount);

        for (uint256 i = 0; i < designCount; i++) {
            designs[i] = battle.designs[i];
        }

        return designs;
    }

    function submitDesign(uint256 battleId, string memory designURI) external {
        require(battles[battleId].startTime != 0, "The battle doestn't exist!");
        require(block.timestamp >= battles[battleId].startTime, "The battle has not started yet!");
        require(block.timestamp <= battles[battleId].endTime, "Battle Ended");
        require(bytes(designURI).length > 0, "Desgin URI cannot be empty");

        Battle storage battle = battles[battleId];
        uint256 designId = battle.designCount;

        battle.designs[designId] = Design({
            creator: msg.sender,
            designURI: designURI,
            votes: 0
        });
        battle.designCount++;

        emit DesignSubmitted(battleId, designId, msg.sender, designURI);
    }
    function vote(uint256 battleId, uint256 designId) external {
        require(battles[battleId].startTime != 0, "The battle doestn't exist!");
        require(block.timestamp >= battles[battleId].startTime, "The battle has not started yet!");
        require(block.timestamp <= battles[battleId].endTime, "Battle Ended");
        require(designId < battles[battleId].designCount, "Enter the valid Design ID");
        require(!battles[battleId].hasVoted[msg.sender], "Already voted");

        Battle storage battle = battles[battleId];
        battle.designs[designId].votes++;
        battle.hasVoted[msg.sender] = true;

        emit Voted(battleId, designId, msg.sender);
    }

    function declareWinner(uint256 battleId) external {
        require(battles[battleId].startTime != 0, "Battle doesn't exist!");
        require(block.timestamp > battles[battleId].endTime, "Battle is still ON");
        require(!battles[battleId].ended, "Winner already declared");
        require(battles[battleId].designCount > 0, "No designs submitted");

        Battle storage battle = battles[battleId];
        battle.ended = true;

        uint256 winningDesignId;
        uint256 maxVotes;

        for (uint256 i=0; i<battle.designCount; i++){
            if(battle.designs[i].votes > maxVotes){
                maxVotes = battle.designs[i].votes;
                winningDesignId = i;
            }
        }

        emit WinnerDeclared(battleId, winningDesignId, battle.designs[winningDesignId].creator);
    }
}