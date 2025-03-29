// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TwitterX is ERC721URIStorage {
    constructor() ERC721("Decentratwitter", "DAPP") {}

    uint256 public tokenCount;
    uint256 public postCount;

    mapping (uint256 => Post) public posts;
    mapping (address => uint256) public profiles;

    struct Post{
        uint256 id;
        string hash;
        uint256 tipAmount;
        address payable author;
    }

    event PostCreated(
        uint256 id,
        string hash,
        uint256 tipAmount,
        address payable author 
    );
    event PostTipped(
        uint256 id,
        string hash,
        uint256 tipAmount,
        address payable author
    );

    function mint(string memory _tokenURI) external returns (uint256){
        require(bytes(_tokenURI).length>0, "token uri must not be empty");
        tokenCount++;
        _safeMint(msg.sender,tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        setProfile(tokenCount);
        return (tokenCount);

    }

    function setProfile(uint256 _id) public {
        require(ownerOf(_id) == msg.sender, "Must own the nft you want to set as your profile.");
        profiles[msg.sender]=_id;

    }

    function getAllPosts(uint256 _start, uint256 _limit) external  view returns (Post[] memory _posts){
        uint256 end=_start+ _limit;
        if(end> postCount) end=postCount;
        uint256 count = end - _start;
        _posts = new Post[](postCount);
        for(uint256 i=0; i<_posts.length; i++){
            _posts[i] = posts[i+1];
        }

    }
    function getMyNfts() external view returns (uint256[] memory _ids){
        _ids = new uint256[](balanceOf(msg.sender));
        uint256 currentIndex=0;
        uint256 _tokenCount = tokenCount;
        for(uint256 i=0; i<_tokenCount; i++){
            if(ownerOf(i+1) == msg.sender){
                _ids[currentIndex] = i+1;
                currentIndex++;
            }
        }

    }
    function uploadPost (string memory _postHash) external {
        require(
            balanceOf(msg.sender)>0, "Must own a nft to post"
        );
        require(bytes(_postHash).length > 0, "Cannot pass empty hash");
        postCount++;
        posts[postCount] = Post(postCount, _postHash, 0,payable(msg.sender));

        emit PostCreated(postCount, _postHash,0,payable(msg.sender));
    }

    function tipPostOwner(uint256 _id) external payable {
        require(_id>0&&_id<=postCount, "Invalid");

        Post storage _post = posts[_id];
        require(_post.author != msg.sender, "Cant tip your post");
             
        _post.tipAmount += msg.value;
        _post.author.transfer(msg.value);
        emit PostTipped(_id, _post.hash, _post.tipAmount, _post.author);
    }


}
