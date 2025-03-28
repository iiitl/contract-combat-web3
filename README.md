**Explanation of _safeMint and _setTokenURI in Solidity (ERC-721)**
--In ERC-721 (NFT) smart contracts, _safeMint and _setTokenURI are used to create and manage NFTs securely.

**1. _safeMint(address to, uint256 tokenId)**
This function is responsible for minting (creating) a new NFT and assigning it to a wallet address.

✅ Key Features:
• It safely mints an NFT by checking if the recipient (to) is a contract.
• If to is a smart contract, it ensures that the contract implements IERC721Receiver to prevent NFTs from being locked in a contract that cannot manage them.
• The token ID must be unique.

**Example Usage:**
_safeMint(msg.sender, 1); // Mints an NFT with token ID 1 to the sender


**2. _setTokenURI(uint256 tokenId, string memory uri)**
This function sets the metadata URI for a given NFT.

✅ Key Features:
• Maps a token ID to its metadata URL, which usually contains image, description, and other attributes.
• The URI is typically a link to IPFS or a centralized server.
• It helps store metadata off-chain, reducing gas costs.

**Example Usage:**
_setTokenURI(1, "ipfs://QmX..."); // Assigns a metadata URI to token ID 1


**🚀 How They Work Together**
To create an NFT and assign metadata:
function mintNFT(address to, uint256 tokenId, string memory uri) public {
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
}

This mints an NFT and assigns a metadata URI in one function. 
