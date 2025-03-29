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

    // Modified Collaboration Functions

    function uploadDesignWithCollaboration(
    string memory _tokenURI,
    address[] memory _collaborators,
    uint256[] memory _shares
) external onlyRegisteredArtist {
    for (uint256 i = 0; i < _collaborators.length; i++) {
        require(_collaborators[i] != address(0), "Invalid address");
    }
    require(_collaborators.length == _shares.length, "Mismatched arrays");
    require(_collaborators.length > 0, "No collaborators");
    
    uint256 totalShares;
    for (uint256 i = 0; i < _shares.length; i++) {
        totalShares += _shares[i];
    }
    require(totalShares == 100, "Shares must sum to 100%");

    uint256 tokenId = collaborationCounter++;
    _mint(msg.sender, tokenId);
    _setTokenURI(tokenId, _tokenURI);

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
            emit ProfitDistributed(_tokenId, collab.collaborators[i], share);
        }
    }

    // Function to buy a collaboration design
    function buyCollaboration(uint256 _tokenId) external payable nonReentrant {
        
        require(design.price>0, "Item not for sale");
        
        address previousOwner = ownerOf(_tokenId);
        _transfer(previousOwner, msg.sender, _tokenId);
        userOwnedDesigns[msg.sender].push(_tokenId);
        
        
        distributeProfit(_tokenId, msg.value);
        
        emit DesignBought(_tokenId, msg.sender);
    }

    // View collaborators of a design
    function viewCollaborators(uint256 _tokenId) external view returns (address[] memory, uint256[] memory) {
        Collaboration memory collab = collaborations[_tokenId];
        require(collab.tokenId != 0, "No collaboration found for this token.");
        return (collab.collaborators, collab.shares);
    }
}