// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ResearchEscrow is ReentrancyGuard, Ownable {
    struct ResearchProject {
        uint256 id;
        string title;
        address creator;
        uint256 targetAmount;
        uint256 currentAmount;
        uint256 deadline;
        bool funded;
        bool fundsReleased;
    }

    uint256 private nextProjectId;
    mapping(uint256 => ResearchProject) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions; 
    
    uint256 public fundingReward = 50 * 10**18; // 50 tokens for funding a project
    
    event ProjectCreated(uint256 indexed projectId, string title, address creator, uint256 targetAmount, uint256 deadline);
    event Funded(uint256 indexed projectId, address indexed backer, uint256 amount);
    event FundsReleased(uint256 indexed projectId, uint256 amount);
    event Refunded(uint256 indexed projectId, address indexed backer, uint256 amount);
    event FundsRetrieved(address indexed owner, uint256 amount);

    constructor( ) Ownable(msg.sender){
    }

    receive() external payable {}

    function startResearchCrowdfunding(string memory _title, uint256 _targetAmount, uint256 _duration) external {
        require(_targetAmount > 0, "Target amount must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        uint256 projectId = ++nextProjectId;
        projects[projectId] = ResearchProject({
            id: projectId,
            title: _title,
            creator: msg.sender,
            targetAmount: _targetAmount,
            currentAmount: 0,
            deadline: block.timestamp + _duration,
            funded: false,
            fundsReleased: false
        });

        emit ProjectCreated(projectId, _title, msg.sender, _targetAmount, block.timestamp + _duration);
    }

    function contributeToResearch(uint256 _projectId) external payable nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(block.timestamp < project.deadline, "Crowdfunding ended");
        require(!project.funded, "Already fully funded");
        require(msg.value > 0, "Must contribute something");

        // Update state before external interactions
        contributions[_projectId][msg.sender] += msg.value;
        project.currentAmount += msg.value;
        
        if (project.currentAmount >= project.targetAmount) {
            project.funded = true;
        }

        emit Funded(_projectId, msg.sender, msg.value);
    }

    function releaseFunds(uint256 _projectId) external nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(msg.sender == project.creator, "Only creator can withdraw funds");
        require(project.funded, "Funding goal not met");
        require(!project.fundsReleased, "Funds already released");

        // Update state before transfer
        project.fundsReleased = true;
        uint256 amount = project.currentAmount;
        project.currentAmount = 0;
        // External interaction last
        payable(project.creator).transfer(amount);

        emit FundsReleased(_projectId, amount);
    }

    function claimRefund(uint256 _projectId) external nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(block.timestamp >= project.deadline, "Crowdfunding is still ongoing");
        require(!project.funded, "Project reached funding goal");
        
        uint256 refundAmount = contributions[_projectId][msg.sender];
        require(refundAmount > 0, "No contributions found");

        // Update state before transfer
        contributions[_projectId][msg.sender] = 0;
        project.currentAmount -= refundAmount;
        
        // External interaction last
        payable(msg.sender).transfer(refundAmount);

        emit Refunded(_projectId, msg.sender, refundAmount);
    }

    function retrieveStuckFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to retrieve");

        payable(owner()).transfer(balance);
        emit FundsRetrieved(owner(), balance);
    }

    function getResearchProject(uint256 _projectId) external view returns (
        string memory, address, uint256, uint256, uint256, bool, bool
    ) {
        ResearchProject storage project = projects[_projectId];
        return (
            project.title,
            project.creator,
            project.targetAmount,
            project.currentAmount,
            project.deadline,
            project.funded,
            project.fundsReleased
        );
    }

    function getUserContribution(uint256 _projectId, address _user) external view returns (uint256) {
        return contributions[_projectId][_user];
    }
    
    function setFundingReward(uint256 _newReward) external onlyOwner {
        fundingReward = _newReward;
    }
}
