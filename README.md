# Understanding _safeMint and _setTokenURI

### _safeMint
- **Purpose:**  
  _safeMint is used to mint a new NFT and assign it to a specific address.

- **How It Works:**  
  When you call _safeMint, the function creates a new token with a given token ID and transfers it to the recipient. It also checks if the recipient is a smart contract. If so, it confirms that the contract implements the onERC721Received function, ensuring the NFT isn’t sent to a contract that cannot handle it properly.

### _setTokenURI (Deprecated in New OpenZeppelin Versions)
- **Purpose:**  
  _setTokenURI was originally used to link a token ID to its metadata URI, such as an IPFS link or HTTPS URL pointing to the token’s details.

- **How It Worked:**  
  In older versions of OpenZeppelin’s ERC721URIStorage, calling _setTokenURI(tokenId, uri) associated the given token ID with its metadata. This made it easy to fetch metadata when querying tokenURI.

- **Status:**  
  This function has been deprecated in newer OpenZeppelin versions in favor of a more manual approach to metadata management.

### _tokenURIs Mapping[Alt to _setTokenURI]
- **Purpose:**  
  The _tokenURIs mapping is now used as an alternative to _setTokenURI. It stores the metadata URI for each token ID directly.

- **How It Works:**  
  - When minting a new token, the metadata URI is stored in the _tokenURIs mapping, keyed by the token ID.
  - The tokenURI function is then overridden to retrieve and return the correct URI from the mapping.

- **Benefits:**  
  This approach provides developers with more control over metadata storage and ensures compatibility with the latest OpenZeppelin contract implementations.
