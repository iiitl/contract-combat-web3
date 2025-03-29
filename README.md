##Explain

**_safeMint

_safeMint function was present in 2 files Researchcollab.sol and Twittercollab.sol . 

_safeMint is a function provided by OpenZeppelin's ERC721 contract. It ensures that when an NFT (ERC-721 token) is minted, it is safely received by the recipient.
why using _safemint is better : 

![image](https://github.com/user-attachments/assets/d5bb6c7d-4e3d-4f1b-b893-b3cd3eaa7a4d)

use of _safemint in Researchcollab : 

---we had a function called createResearch : 
 
  The use of _safeMint ensures that:

                 ![image](https://github.com/user-attachments/assets/0dec31b9-31fb-4e12-8938-a22fa615c0c5)


  1.The NFT is properly assigned to the creator (msg.sender).

  2.If the msg.sender is a smart contract, _safeMint checks if it implements onERC721Received.

  3.If yes, the transaction succeeds.

  4.If no, the transaction fails, preventing token loss.


use of _safeMint in TwitterX.sol : 
     
                 ![image](https://github.com/user-attachments/assets/1b05a083-bb2c-4d16-8985-5f05a0e0e759)

The function mint is responsible for minting a new NFT profile for a user. The _safeMint function is used to ensure:

    1.Correct ownership assignment : The newly minted NFT is assigned to the caller (msg.sender).

    2.Security against non-ERC721 receivers : If msg.sender is a smart contract, _safeMint verifies whether it implements onERC721Received.

                                              If the recipient contract does not implement it, the transaction fails, preventing the NFT from being permanently locked.

    3.Automatic Profile Setup : The minted NFT is set as the user’s profile (setProfile(tokenCount);). 

   


    



**_setTokenURI 

In your ResearchCollab contract, _setTokenURI is used to store and update the metadata URI of each NFT. It comes from the ERC721URIStorage extension of OpenZeppelin's ERC721 contract.


                  ![image](https://github.com/user-attachments/assets/ca68f0f7-952f-480d-a5aa-427dfb75a513)


What Does _setTokenURI Do?

The function _setTokenURI(uint256 tokenId, string memory _tokenURI):

  1.Assigns a metadata URI to a given NFT.

  2.Enables storing off-chain data (like research details) using IPFS, Arweave, or other decentralized storage solutions.

  3.Updates the URI when the research is modified.

  4.When the research is modified, _setTokenURI updates the NFT with the new metadata URI.


In Twitterx.sol contract : 


               ![image](https://github.com/user-attachments/assets/2fe38808-ae63-46ed-8776-5e5572e134ed)


   1._setTokenURI() binds NFT metadata to a token
   
   2.Stores profile picture off-chain in IPFS
   
   3.Allows unique metadata per NFT
   
   4.Supports decentralized storage


   https://www.reddit.com/r/ethdev/comments/13xy3qt/erc721_smart_contract_best_strategy_for_handling/

   





