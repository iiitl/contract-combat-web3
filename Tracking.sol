// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Tracking {
    // Constants for shipment status
    // uint256 public constant STATUS_PENDING = 0;
    // uint256 public constant STATUS_IN_TRANSIT = 1;
    // uint256 public constant STATUS_DELIVERED = 2;

    enum ShipmentStatus{
        PENDING,
        IN_TRANSIT,
        DELIVERED
    }

    struct Shipment {
        uint256 shipmentId;
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 estimatedDeliveryTime;
        uint256 distance;
        uint256 price;
        uint256 paidAmount;
        ShipmentStatus status;
        bool isPaid;
        string location;
        uint16 rating;
        string feedback;
    }

    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    event ShipmentCreated(address indexed sender, address indexed receiver, uint256 pickupTime, uint256 estimatedDeliveryTime, uint256 distance, uint256 price);
    event ShipmentUpdated(uint256 indexed shipmentId, string location);
    event ShipmentDelivered(uint256 indexed shipmentId, address indexed sender, address indexed receiver, uint256 deliveryTime);
    event ShipmentPaid(uint256 indexed shipmentId, address indexed sender, address indexed receiver, uint256 amount);
    event ShipmentRated(uint256 indexed shipmentId, uint8 rating, string feedback);

    constructor() {
        shipmentCount = 0;
    }

    function createShipment(address _receiver, uint256 _pickupTime, uint256 _estimatedDeliveryTime ,uint256 _distance, uint256 _price) public payable {
        require(msg.value == _price, "Payment amount must match the price");
        require(_estimatedDeliveryTime > _pickupTime, "Estimated delivery time should be greater than pick up time");
        shipmentCount++;
        Shipment memory shipment = Shipment(
            shipmentCount,
            msg.sender,
            _receiver,
            _pickupTime,
            0,
            _estimatedDeliveryTime,
            _distance,
            _price,
            msg.value,
            ShipmentStatus.PENDING,
            false,
            "Initial Location,Shipment not started",
            0,
            "Feedback not given yet"
        );
        shipments[msg.sender].push(shipment);
        emit ShipmentCreated(msg.sender, _receiver, _pickupTime,_estimatedDeliveryTime, _distance, _price);
    }

    function updateLocation(address _sender,uint256 _index,string memory _location) public{
        Shipment storage shipment = shipments[_sender][_index];
        shipment.location = _location;
          emit ShipmentUpdated(shipment.shipmentId, _location);
    }

    function startShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.PENDING, "Shipment is not pending");

        shipment.status = ShipmentStatus.IN_TRANSIT;
    }

    function completeShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.IN_TRANSIT, "Shipment is not in transit");
        require(!shipment.isPaid, "Shipment already paid");

        shipment.status = ShipmentStatus.DELIVERED;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount);
        shipment.isPaid = true;

        emit ShipmentDelivered(shipment.shipmentId,_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(shipment.shipmentId,_sender, _receiver, amount);
    }

    function getShipment(address _sender, uint256 _index) public view returns (
        uint256,address, address, uint256, uint256, uint256, uint256,uint256,ShipmentStatus, bool,string memory ,
        uint16, string memory
    ) {
        require(_index < shipments[_sender].length, "Invalid shipment index");
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.shipmentId,
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.deliveryTime,
            shipment.estimatedDeliveryTime,
            shipment.distance,
            shipment.price,
            shipment.status,
            shipment.isPaid,
            shipment.location,
            shipment.rating,
            shipment.feedback

        );
    }

    function getShipmentsCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }

     function rateShipment(address _sender, uint256 _index, uint8 _rating, string memory _feedback) public {
        Shipment storage shipment = shipments[_sender][_index];
        require(shipment.status == ShipmentStatus.DELIVERED, "Shipment not delivered yet");
        require(shipment.receiver == msg.sender, "Only receiver can rate");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        shipment.rating = _rating;
        shipment.feedback = _feedback;
        emit ShipmentRated(shipment.shipmentId, _rating, _feedback);
    }
}
