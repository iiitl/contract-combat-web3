Hi !

I have explained these two functions & their uses in the following manner 

a. what are these functions ?
b. How it works & its usecase?
c.Its key features and Use cases 
d.Advantages and disadvantages of these functions 

1. Everything about _safeMint Function :)
   a. This is an important functions used in NFT (Non-Fungible Token) smart contract development, typically when working with ERC-721 standards on Ethereum and other EVM-compatible blockchains.
      This is a function used to create (mint) new NFTs in a safe manner. It's an extension of the basic _mint function with additional safety checks.
   b. It works by assigning new token to the given ID. It assigns ownership to the specified address.
   c. - It checks the recipient address , if it is found valid it can recieves ERC721 tokens
      - Prevents accidental locking of tokens in contracts that don't know how to handle them
      - Emits a Transfer event
      - It mints new NFT's and also helps in distribution of it
   d. Safer than basic _mint as it prevents tokens being stuck in contracts 
      Slightly more gas expensive than _mint

2. Everything about _setTokenURI Function :)
   a.  This is an important functions used in NFT (Non-Fungible Token) smart contract development, typically when working with ERC-721 standards on Ethereum and other EVM-compatible blockchains.
       it connects metadata with a specific NFT token ID
   b.  Takes a token ID and a URI string as input
       Stores the URI in the contract's storage
       Makes the URI retrievable via the tokenURI() function
   c.  -these store IPFS hashes or normal HTTP/HTTPS URLs
       -URI points to a JSON file with metadata stds.
       -It is used in Updating NFTs metadata (if permitted in contract rules)
   d. It can point to any URI scheme & gives a rich NFT experience which is an advantage



HOPE THIS HELPS :)
