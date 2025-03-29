##Explain

**_safeMint

It is inherited from OpenZeppelin’s ERC721 contract, it securely mints an ERC721 token to a specified address.

It ensures the recipient is either an Externally Owned Account (EOA) or a contract that implements the onERC721Received function (part of the IERC721Receiver interface). This prevents tokens from being locked in contracts that cannot interact with them.


Before using _safeMint we should ensure that :

1.The contract must inherit ERC721 (or a derivative like ERC721URIStorage).

2.tokenId must not already exist.


Implementation in the Code:

_safeMint(msg.sender, tokenId);


The token is minted to msg.sender (the artist) this ensures the artist owns the token before transferring/selling it.

TokenId: uses tokenCounter to assign a unique ID. The ID is incremented (tokenId++) after minting to avoid duplication.


for issue #13 ([feat]: Implement mintMembershipNFT Function) we have to use _mint but for issue #12 ([feat]: Complete singleUploadDesign Function) we have to use _safeMint. The question is why so?

_mint does not perform safety checks. If the recipient is a contract that cannot handle ERC721 tokens, the token becomes stuck.

While _safeMint protects against accidental loss of tokens by reverting if the recipient is incompatible.

![Screenshot 2025-03-29 192706](https://github.com/user-attachments/assets/07aa4a4e-a189-40d0-8db4-a70d11bdf3b1)

![Screenshot 2025-03-29 192544](https://github.com/user-attachments/assets/7bd49353-d11c-4dcf-bf74-2ab5fae10b98)



**_setTokenURI

It basically assigns a metadata URI (like IPFS link) to a token ID. This URI typically points to a JSON file describing the NFT’s attributes (name, image, etc.).


Before using _setTokenURI we should ensure that : 
1.It also requires the contract to inherit ERC721URIStorage, an OpenZeppelin extension for URI management.
2.It is called after minting (_safeMint), ensuring the tokenId exists.


It is necessary to use _setTokenURI because ERC721 tokens are not useful without metadata. This function links the token to its off-chain data.

The URI is stored in the contract’s state, allowing external platforms (like OpenSea) to fetch metadata via tokenURI(tokenId).


Implementation in the Code:

_setTokenURI(tokenId, _tokenURI);


References taken from: https://docs.openzeppelin.com/contracts/2.x/api/token/erc721




