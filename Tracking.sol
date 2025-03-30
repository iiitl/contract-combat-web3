// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Tracking {
    // Constants for shipment status
    // uint256 public constant STATUS_PENDING = 0;
    // uint256 public constant STATUS_IN_TRANSIT = 1;
    // uint256 public constant STATUS_DELIVERED = 2;
    enum Status {
        STATUS_PENDING,
        STATUS_IN_TRANSIT,
        STATUS_DELIVERED
    }
    mapping(bytes32 => string) shipmentLocations;
    // Status public currentStatus;
    struct Shipment {
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 estimatedDeliveryTime;
        uint256 distance;
        uint256 price;
        Status status;
        bool isPaid;
        bytes32 shipmentId;
    }
        struct Feedback {
    uint8 rating; 
    string comment; 
}
    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    event ShipmentCreated(
        address indexed sender,
        address indexed receiver,
        uint256 pickupTime,
        uint256 distance,
        uint256 price
    );
    event ShipmentUpdated(
        address indexed sender,
        address indexed receiver,
        uint256 pickupTime
    );
    event ShipmentDelivered(
        address indexed sender,
        address indexed receiver,
        uint256 deliveryTime
    );
    event ShipmentPaid(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
    event LocationUpdated(bytes32 indexed shipmentId, string location);

    constructor() {
        shipmentCount = 0;
    }

    function createShipment(
        address _receiver,
        uint256 _pickupTime,
        uint256 _distance,
        uint256 _price,
        uint256 _estimatedDeliveryTime
    ) public payable {
        require(msg.value == _price, "Payment amount must match the price");
        bytes32 shipmentId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                _pickupTime,
                shipmentCount,
                block.timestamp
            )
        );
        Shipment memory shipment = Shipment(
            msg.sender,
            _receiver,
            _pickupTime,
            0,
            _estimatedDeliveryTime,
            _distance,
            _price,
            Status.STATUS_PENDING,
            false,
            shipmentId
        );
        shipments[msg.sender].push(shipment);
        shipmentCount++;
        emit ShipmentCreated(
            msg.sender,
            _receiver,
            _pickupTime,
            _distance,
            _price
        );
    }

    function startShipment(
        address _sender,
        address _receiver,
        uint256 _index
    ) public payable {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(
            shipment.status == Status.STATUS_PENDING,
            "Shipment is not pending"
        );
        require(
            msg.value == shipment.price / 2,
            "Partial payment required to start shipment"
        );
        shipment.status = Status.STATUS_IN_TRANSIT;
        emit ShipmentUpdated(_sender, _receiver, shipment.pickupTime);
    }

    function completeShipment(
        address _sender,
        address _receiver,
        uint256 _index
    ) public payable {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(
            shipment.status == Status.STATUS_IN_TRANSIT,
            "Shipment is not in transit"
        );
        require(!shipment.isPaid, "Shipment already paid");
        require(
            msg.value == shipment.price / 2,
            "Final payment required to complete shipment"
        );
        shipment.status = Status.STATUS_DELIVERED;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount);
        shipment.isPaid = true;

        emit ShipmentDelivered(_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(_sender, _receiver, amount);
    }

    function getShipment(
        address _sender,
        uint256 _index
    )
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bytes32
        )
    {
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.deliveryTime,
            shipment.distance,
            shipment.price,
            uint256(shipment.status),
            shipment.isPaid,
            shipment.shipmentId
        );
    }

    function getShipmentsCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }

    function updateLocation(
        bytes32 _shipmentId,
        string memory _location
    ) public {
         bool isAuthorized = false;
             for (uint256 i = 0; i < shipments[msg.sender].length; i++) {
        if (shipments[msg.sender][i].shipmentId == _shipmentId) {
            isAuthorized = true;
            break;
        }
    }
    require(isAuthorized, "Only the sender or receiver can update the location");
        shipmentLocations[_shipmentId] = _location;
        emit LocationUpdated(_shipmentId, _location);
    }

    function getLocation(
        bytes32 _shipmentId
    ) public view returns (string memory) {
        return shipmentLocations[_shipmentId];
    }

mapping(bytes32 => Feedback) public shipmentFeedbacks; 

event FeedbackSubmitted(bytes32 indexed shipmentId, uint8 rating, string comment);

function submitFeedback(bytes32 _shipmentId, uint8 _rating, string memory _comment) public {
    require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5");
    Feedback memory feedback = Feedback(_rating, _comment);
    shipmentFeedbacks[_shipmentId] = feedback;

    emit FeedbackSubmitted(_shipmentId, _rating, _comment);
}

function getFeedback(bytes32 _shipmentId) public view returns (uint8, string memory) {
    Feedback memory feedback = shipmentFeedbacks[_shipmentId];
    return (feedback.rating, feedback.comment);
}
}
