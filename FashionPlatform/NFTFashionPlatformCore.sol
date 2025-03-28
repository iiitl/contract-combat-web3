// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTFashionPlatformCore is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    struct Artist {
        string name;
        string profileURI;
        bool registered;
    }

    struct Design {
        uint256 tokenId;
        string designURI;
        address creator;
        string category; // "General" or "Premium"
        string designType; // "Clothing" or "Fabric"
        uint256 price;
        uint256 likes;
    }

    mapping(address => Artist) public artists;
    mapping(uint256 => Design) public designs;
    mapping(address => uint256[]) public userOwnedDesigns;
    mapping(uint256 => string[]) public communityPosts;
    mapping(address => uint256[]) public artistMembershipNFTs;


    event ArtistRegistered(address indexed artist, string name);
    event DesignUploaded(uint256 indexed tokenId, address indexed creator, string category, string designType);
    event DesignBought(uint256 indexed tokenId, address indexed buyer);
    event DesignLiked(uint256 indexed tokenId, address indexed liker);
    event CommunityPostAdded(uint256 indexed tokenId, string content);
    event MembershipNFTMinted(address indexed artist, address indexed minter, uint256 tokenId);


    constructor() ERC721("FashionNFT", "FASHION") Ownable(msg.sender) {
        tokenCounter = 1;
    }

    modifier onlyRegisteredArtist() {
        require(artists[msg.sender].registered, "You must be a registered artist.");
        _;
    }

    function registerArtist(string memory _name, string memory _profileURI) external {
        require(!artists[msg.sender].registered, "Artist already registered.");
        artists[msg.sender] = Artist(_name, _profileURI, true);
        emit ArtistRegistered(msg.sender, _name);
    }

    function singleUploadDesign(
        string memory _tokenURI,
        string memory _category,
        string memory _designType,
        uint256 _price
    ) external onlyRegisteredArtist {
        require(
            keccak256(abi.encodePacked(_category)) == keccak256(abi.encodePacked("General")) ||
            keccak256(abi.encodePacked(_category)) == keccak256(abi.encodePacked("Premium")),
            "Invalid category"
        );
        require(
            keccak256(abi.encodePacked(_designType)) == keccak256(abi.encodePacked("Clothing")) ||
            keccak256(abi.encodePacked(_designType)) == keccak256(abi.encodePacked("Fabric")),
            "Invalid design type"
        );
        require(_price > 0, "Price must be greater than 0.");


    }

    function buyDesign(uint256 _tokenId) external payable {
        Design memory design = designs[_tokenId];
        require(design.tokenId != 0, "Design does not exist.");
        require(msg.sender != design.creator, "Creator cannot buy their own design.");
        require(msg.value >= design.price, "Insufficient Ether sent.");

        address creator = design.creator;
        payable(creator).transfer(msg.value);

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
        userOwnedDesigns[msg.sender].push(_tokenId);

        emit DesignBought(_tokenId, msg.sender);
    }

    function likeDesign(uint256 _tokenId) external {
        require(designs[_tokenId].tokenId != 0, "Design does not exist.");
        designs[_tokenId].likes += 1;
        emit DesignLiked(_tokenId, msg.sender);
    }

    function addCommunityPost(uint256 _tokenId, string memory _content) external {
        require(designs[_tokenId].tokenId != 0, "Design does not exist.");
        require(bytes(_content).length > 0, "Content cannot be empty.");
        communityPosts[_tokenId].push(_content);
        emit CommunityPostAdded(_tokenId, _content);
    }
    function mintMembershipNFT(address artist) external {
    
}
 function canViewPremiumNFTs(address artist, address viewer) public view returns (bool) {
  uint256[] memory membershipNFTs = artistMembershipNFTs[viewer];
    for (uint256 i = 0; i < membershipNFTs.length; i++) {
        if (ownerOf(membershipNFTs[i]) == viewer) {
            return true;
        }
    }
    return false;
    }
}