# Explain

**_safeMint**
> Minting means creating a new Non-Fungible Token (NFT) and giving it to an address , its like printing a unique vip ticket and handing it to a person
> Its a function in  in smart contracts (specifically in ERC721( a standard for NFTs) )

> Safe Minting is same but it assign it to someone safely
> it first checks if the receiver can accept it (if its a smart contract) or in real world example it checks before if receiver have hands ✋ to receive it

>If the NFT is sent to a smart contract that doesn’t support NFTs, the token could be lost forever.

> And that's the difference btw mint and smartmint function

**_setTokenURI**

> NFT is just a token(id).
> The image of those monkeys 🐵 we see as an example is just the image associated with the token. Other than image name , description is also associated and stored as metadata in JSON file

> The metadata is stored on IPFS(Interplanetary File System) which is a decentralized file storage system

> Finally its the setTokeURI that links NFT to metadata file

>  _setTokenURI(tokenId, tokenURI); 
