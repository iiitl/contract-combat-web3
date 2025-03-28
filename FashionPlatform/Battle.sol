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

     function submitDesign(uint256 _battleId,string memory _designURI) external {
        require(battles[_battleId].startTime != 0, "Battle does not exist");
        require(battles[_battleId].ended == false, "Battle has already ended");
        require(block.timestamp >= battles[_battleId].startTime,"Battle not started yet");
        require(block.timestamp <= battles[_battleId].endTime,"Battle has already ended");

        Battle storage battle = battles[_battleId];
        uint256 designId = battle.designCount;

        battle.designs[designId] = Design({
            creator: msg.sender,
            designURI: _designURI,
            votes: 0
        });

        battle.designCount++;

        emit DesignSubmitted(_battleId, designId, msg.sender, _designURI);
    }
   

    function vote(uint256 _battleId, uint256 _designId) external {
        require(battles[_battleId].startTime != 0, "Battle does not exist");
        require(battles[_battleId].ended == false, "Battle has already ended");
        require(block.timestamp >= battles[_battleId].startTime,"Battle not started yet");
        require(block.timestamp <= battles[_battleId].endTime,"Battle has already ended");

        require(battles[_battleId].hasVoted[msg.sender] == false,"A voter can vote only once");

        Battle storage battle = battles[_battleId];
        require(_designId < battle.designCount, "Invalid Design ID");
        battle.hasVoted[msg.sender] = true;
        battle.designs[_designId].votes += 1;

        emit Voted(_battleId, _designId, msg.sender);
    }

     function declareWinner(uint256 _battleId) external {
        require(battles[_battleId].startTime != 0, "Battle does not exist");
        require(block.timestamp > battles[_battleId].endTime,"Battle is still ongoing");
        require(battles[_battleId].ended = false, "Winner already declared");

        Battle storage battle = battles[_battleId];
        uint256 designCount = battle.designCount;
        uint256 maxvotes = 0;
        uint256 winningId = 0;
        address winner = address(0);

        for (uint256 i = 0; i < designCount; i++) {
            if (battle.designs[i].votes > maxvotes) {
                maxvotes = battle.designs[i].votes;
                winningId = i;
                winner = battle.designs[i].creator;
            }
        }
        battle.ended = true;
        emit WinnerDeclared(_battleId, winningId, winner);
    }
}
