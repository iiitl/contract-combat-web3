These functions are commonly used in ERC-721 smart contracts (Non-Fungible Tokens) in Solidity. They come from the OpenZeppelin implementation of ERC-721.

1. **_safeMint(address to, uint256 tokenId)
This function is responsible for minting (creating) a new NFT and safely assigning it to an address.

✅ Key Features:
Mints a new token (tokenId) and assigns it to the to address.

Ensures that the recipient (to) is capable of receiving NFTs.

If to is a smart contract, it checks whether the contract implements onERC721Received to prevent accidental token loss.

Uses internal visibility (accessible only within the contract or derived contracts).

🔹 Example Usage:
solidity
Copy
Edit
_safeMint(msg.sender, 1); // Mint token ID 1 to the sender
2. **_setTokenURI(uint256 tokenId, string memory tokenURI)
This function sets the metadata URI for a specific token.

✅ Key Features:
Assigns a tokenURI (metadata location) to a token ID.

Helps link NFTs to metadata stored off-chain (like IPFS, Arweave, or centralized storage).

Usually used in combination with _safeMint to define metadata for newly minted NFTs.

Uses internal visibility (only accessible within the contract or derived contracts).

🔹 Example Usage:
solidity
Copy
Edit
_setTokenURI(1, "ipfs://Qm..."); // Assign a metadata URI to token ID 1
🔥 How They Work Together
When minting a new NFT, you typically use both functions:

solidity
Copy
Edit
function mintNFT(address to, uint256 tokenId, string memory tokenURI) public {
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
}
This ensures:

The token is safely minted.

The token is linked to metadata.