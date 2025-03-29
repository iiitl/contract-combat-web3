// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract TwitterX is ERC1155, Ownable {
    constructor() ERC1155("https://example.com/api/token/{id}.json") {}
    
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

    function mint(uint256 amount) external returns (uint256){
        tokenCount++;
        _mint(msg.sender, tokenCount, amount, "");
        setProfile(tokenCount);
        return (tokenCount);

    }

    function setProfile(uint256 _id) public {
        require(balanceOf(msg.sender, _id) > 0, "Must own the NFT to set as profile.");
        profiles[msg.sender]=_id;

    }

    function getAllPosts() external  view returns (Post[] memory _posts){
        _posts = new Post[](postCount);
        for(uint256 i=0; i<_posts.length; i++){
            _posts[i] = posts[i+1];
        }

    }
    function getMyNfts() external view returns (uint256[] memory _ids){
        uint256 count = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (balanceOf(msg.sender, i) > 0) {
                count++;
            }
        }

        _ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (balanceOf(msg.sender, i) > 0) {
                _ids[index] = i;
                index++;
            }
        }

    }
    function uploadPost (string memory _postHash) external {
        require(balanceOf(msg.sender, profiles[msg.sender]) > 0, "Must own an NFT to post.");
        require(bytes(_postHash).length > 0, "Cannot pass empty hash");
        postCount++;
        posts[postCount] = Post(postCount, _postHash, 0,payable(msg.sender));

        emit PostCreated(postCount, _postHash,0,payable(msg.sender));
    }

    function tipPostOwner(uint256 _id) external payable {
        require(_id>0&&_id<=postCount, "Invalid");

        Post memory _post = posts[_id];
        require(_post.author != msg.sender, "Cant tip your post");

        _post.author.transfer(msg.value);
        _post.tipAmount += msg.value;

        emit PostTipped(_id, _post.hash, _post.tipAmount, _post.author);
    }


}
