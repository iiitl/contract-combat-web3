// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTFashionPlatformCore.sol";

contract NFTFashionPlatformCollaboration is NFTFashionPlatformCore {

    uint256 public collaborationCounter;
    mapping(uint256 => Collaboration) public collaborations;

    struct Collaboration {
        uint256 tokenId;
        string collabURI;
        address[] collaborators;
        uint256[] shares; // Percentage shares for each collaborator
    }

    event CollaborationCreated(uint256 indexed tokenId, address[] collaborators, uint256[] shares);

    constructor() NFTFashionPlatformCore() {
        collaborationCounter = 1;
    }

    // Existing Collaboration Functions

    function uploadDesignWithCollaboration(
        string memory _tokenURI,
        address[] memory _collaborators,
        uint256[] memory _shares
    ) 
    
    external onlyRegisteredArtist {
    require(_collaborators.length > 0, "At least one collaborator required.");
        require(_collaborators.length == _shares.length, "Mismatch in collaborators and shares count.");
        
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
    }

    require(totalShares == 100, "Total shares must sum to 100.");

    uint256 tokenId = mintNFT(_tokenURI);

    collaborations[tokenId] = Collaboration({
            tokenId: tokenId,
            collabURI: _tokenURI,
            collaborators: _collaborators,
            shares: _shares
        });
        
        emit CollaborationCreated(tokenId, _collaborators, _shares);
    }

    // Profit distribution function
    function distributeProfit(uint256 _tokenId, uint256 _amount) internal {
        Collaboration memory collab = collaborations[_tokenId];
        require(collab.tokenId != 0, "No collaboration found for this token.");

        for (uint256 i = 0; i < collab.collaborators.length; i++) {
            payable(collab.collaborators[i]).transfer((_amount * collab.shares[i]) / 100);
        }
    }

    // Function to buy a collaboration design
    function buyCollaboration(uint256 _tokenId) external payable {
        Collaboration memory collab = collaborations[_tokenId];
        require(collab.tokenId != 0, "Collaboration does not exist.");

        Design memory design = designs[_tokenId];
        require(msg.value >= design.price, "Insufficient Ether sent.");

        distributeProfit(_tokenId, msg.value);

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
        userOwnedDesigns[msg.sender].push(_tokenId);

        emit DesignBought(_tokenId, msg.sender);
    }

    // View collaborators of a design
    function viewCollaborators(uint256 _tokenId) external view returns (address[] memory, uint256[] memory) {
        Collaboration memory collab = collaborations[_tokenId];
        require(collab.tokenId != 0, "No collaboration found for this token.");
        return (collab.collaborators, collab.shares);
    }
}