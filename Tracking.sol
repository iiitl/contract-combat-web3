// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Tracking {
    // Constants for shipment status
    enum ShipmentStatus { Pending, InTransit, Delivered }

    struct Shipment {
        uint256 id;
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 estimatedDeliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status;
        bool isPaid;
        bool isRated;
    }

    struct Rating {
        uint8 score;
        string comment;
    }

    mapping(address => Shipment[]) public shipments;
    mapping(uint256 => Rating) public shipmentRatings;
    mapping(address => uint256[]) public senderShipments;
    uint256 public shipmentCount;

    event ShipmentCreated(uint256 indexed shipmentId, address indexed sender, address indexed receiver, uint256 amount);
    event ShipmentUpdated(uint256 indexed shipmentId);
    event ShipmentDelivered(uint256 indexed shipmentId);
    event ShipmentPaid(uint256 indexed shipmentId, uint256 amount);
    event ShipmentRated(uint256 indexed shipmentId, uint8 score, string comment);


    constructor() {
        shipmentCount = 0;
    }

    function createShipment(address _receiver, uint256 _pickupTime, uint256 _estimatedDeliveryTime, uint256 _distance, uint256 _price) public payable {
        require(msg.value == _price, "Payment amount must match the price");
        uint256 shipmentId = shipmentCount++;
        Shipment memory shipment = Shipment(
            shipmentId, 
            msg.sender,
            _receiver,
            _pickupTime,
            0,
            _estimatedDeliveryTime,
            _distance,_price,
            ShipmentStatus.Pending,
            false,
            false

        );
        senderShipments[msg.sender].push(shipmentId);
        emit ShipmentCreated(shipmentId, msg.sender, _receiver, _price);
    }

    function startShipment(uint256 shipmentId) public {
        Shipment storage shipment = shipments[msg.sender][shipmentId];
        require(msg.sender == shipment.sender, "Unauthorized");
        require(shipment.status == ShipmentStatus.Pending, "Invalid status");
        
        shipment.status = ShipmentStatus.InTransit;
        emit ShipmentUpdated(shipmentId);
    }

    function completeShipment(uint256 shipmentId) public {
        Shipment storage shipment = shipments[msg.sender][shipmentId];
        require(msg.sender == shipment.receiver, "Unauthorized");
        require(shipment.status == ShipmentStatus.InTransit, "Invalid status");
        require(!shipment.isPaid, "Already paid");

        shipment.status = ShipmentStatus.Delivered;
        shipment.deliveryTime = block.timestamp;
        shipment.isPaid = true;
        
        payable(shipment.sender).transfer(shipment.price);
        emit ShipmentDelivered(shipmentId);
        emit ShipmentPaid(shipmentId, shipment.price);
    }

    function rateShipment(uint256 shipmentId, uint8 score, string calldata comment) public {
        Shipment storage shipment = shipments[msg.sender][shipmentId];
        require(msg.sender == shipment.receiver, "Only receiver can rate");
        require(shipment.status == ShipmentStatus.Delivered, "Shipment not delivered");
        require(!shipment.isRated, "Already rated");
        require(score >= 1 && score <= 5, "Invalid rating (1-5)");

        shipmentRatings[shipmentId] = Rating(score, comment);
        shipment.isRated = true;
        emit ShipmentRated(shipmentId, score, comment);
    }

    function getShipmentRating(uint256 shipmentId) public view returns (uint8 score, string memory comment) {
        Rating memory rating = shipmentRatings[shipmentId];
        return (rating.score, rating.comment);
    }

     function getShipment(uint256 shipmentId) public view returns (
        address sender,
        address receiver,
        uint256 pickupTime,
        uint256 deliveryTime,
        uint256 estimatedDeliveryTime,
        uint256 distance,
        uint256 price,
        ShipmentStatus status,
        bool isPaid,
        bool isRated
    ) {
        Shipment memory s = shipments[msg.sender][shipmentId];
        return (
            s.sender,
            s.receiver,
            s.pickupTime,
            s.deliveryTime,
            s.estimatedDeliveryTime,
            s.distance,
            s.price,
            s.status,
            s.isPaid,
            s.isRated
        );
    }

    function getShipmentsCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }
}