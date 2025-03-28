// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdvancedTracking {
    enum shipStatus { PENDING, IN_TRANSIT, DELIVERED }
    enum payStatus { UNPAID, PARTIALLY_PAID, FULLY_PAID }

    struct Location {
        string lat;// wrote for latitude 
        string longi;// wrote for longitude
        uint256 timestamp;
    }

    struct Feedback {
        uint8 rating; // 1-5 stars
        string comment; // 
        uint256 timestamp;
    }

    struct Shipment {
        uint256 id; // Unique shipment ID
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 esmtdDelTime;//estimated delivery time
        uint256 distance;
        uint256 price;
        uint256 amountPaid;
        shipStatus status;
        payStatus payStatus;
        Location[] locations;
        Feedback feedback;
    }

    mapping(uint256 => Shipment) public shipments;
    mapping(address => uint256[]) public userShipments;
    uint256 public shipmentCount;
    uint256 public constant MinR = 1;
    uint256 public constant MaxR = 5;

    event ShipmentCreated(uint256 indexed id, address indexed sender, address indexed receiver);
    event LocationUpdated(uint256 indexed id, string lat, string longi);
    event PaymentReceived(uint256 indexed id, uint256 amount);
    event ShipmentDelivered(uint256 indexed id);
    event FeedbackSubmitted(uint256 indexed id, uint8 rating);

    constructor() {
        shipmentCount = 0;
    }

    function createShipment(
        address _receiver,
        uint256 _pickupTime,
        uint256 _distance,
        uint256 _price,
        uint256 _esmtdDelTime,//estimated delivery time
        string memory _initialLat,
        string memory _initialLong
    ) public payable {
        require(msg.value > 0, "Initial payment required");
        require(msg.value <= _price, "Payment cannot exceed total price");

        uint256 newId = ++shipmentCount;
        
        Shipment storage shipment = shipments[newId];
        shipment.id = newId;
        shipment.sender = msg.sender;
        shipment.receiver = _receiver;
        shipment.pickupTime = _pickupTime;
        shipment.esmtdDelTime = _esmtdDelTime; //estimated delivery time
        shipment.distance = _distance;
        shipment.price = _price;
        shipment.amountPaid = msg.value;
        shipment.status = shipStatus.PENDING;
        shipment.payStatus = msg.value == _price ? payStatus.FULLY_PAID : payStatus.PARTIALLY_PAID;
        
        // for initial location
        shipment.locations.push(Location(_initialLat, _initialLong, block.timestamp));
        
        userShipments[msg.sender].push(newId);
        userShipments[_receiver].push(newId);

        emit ShipmentCreated(newId, msg.sender, _receiver);
    }

    function updateLocation(
        uint256 _id,
        string memory _lat,
        string memory _longi
    ) public {
        Shipment storage shipment = shipments[_id];
        require(msg.sender == shipment.sender, "Only sender can update location");
        require(shipment.status == shipStatus.IN_TRANSIT, "Shipment must be in transit");
        
        shipment.locations.push(Location(_lat, _longi, block.timestamp));
        emit LocationUpdated(_id, _lat, _longi);
    }

    function makePayment(uint256 _id) public payable {
        Shipment storage shipment = shipments[_id];
        require(msg.sender == shipment.receiver, "Only receiver can make payments");
        require(shipment.status != shipStatus.DELIVERED, "Shipment already delivered");

        uint256 remainingAmount = shipment.price - shipment.amountPaid;
        require(msg.value <= remainingAmount, "Payment exceeds remaining balance");
        
        shipment.amountPaid += msg.value;
        if (shipment.amountPaid == shipment.price) {
            shipment.payStatus = payStatus.FULLY_PAID;
        }
        
        payable(shipment.sender).transfer(msg.value);
        emit PaymentReceived(_id, msg.value);
    }

    function completeShipment(uint256 _id) public {
        Shipment storage shipment = shipments[_id];
        require(msg.sender == shipment.receiver, "Only receiver can complete shipment");
        require(shipment.status == shipStatus.IN_TRANSIT, "Shipment must be in transit");
        require(shipment.payStatus == payStatus.FULLY_PAID, "Full payment required");
        
        shipment.status = shipStatus.DELIVERED;
        shipment.deliveryTime = block.timestamp;
        emit ShipmentDelivered(_id);
    }

    function submitFeedback(
        uint256 _id,
        uint8 _rating,
        string memory _comment
    ) public {
        require(_rating >= MinR && _rating <= MaxR, "Invalid rating");
        Shipment storage shipment = shipments[_id];
        require(msg.sender == shipment.receiver, "Only receiver can submit feedback");
        require(shipment.status == shipStatus.DELIVERED, "Shipment must be delivered");
        require(shipment.feedback.timestamp == 0, "Feedback already submitted");
        
        shipment.feedback = Feedback(_rating, _comment, block.timestamp);
        emit FeedbackSubmitted(_id, _rating);
    }

    // to see & track the order 
    function getShipment(uint256 _id) public view returns (
        uint256, address, address, uint256, uint256, uint256, uint256, 
        uint256, shipStatus, payStatus, Feedback memory
    ) {
        Shipment memory shipment = shipments[_id];
        return (
            shipment.id,
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.deliveryTime,
            shipment.esmtdDelTime,//estimated delivery time
            shipment.distance,
            shipment.price,
            shipment.status,
            shipment.payStatus,
            shipment.feedback
        );
    }

    function getLocations(uint256 _id) public view returns (Location[] memory) {
        return shipments[_id].locations;
    }

    function getUserShipments(address _user) public view returns (uint256[] memory) {
        return userShipments[_user];
    }
}
