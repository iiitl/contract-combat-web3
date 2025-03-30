// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Tracking {
    // Define enum for shipment status for better readability
    enum ShipmentStatus { PENDING, IN_TRANSIT, DELIVERED }

    // Keeping the old constants for compatibility references
    uint256 public constant STATUS_PENDING = 0;
    uint256 public constant STATUS_IN_TRANSIT = 1;
    uint256 public constant STATUS_DELIVERED = 2;

    struct Shipment {
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status; 
        bool isPaid;
        uint256 estimatedDeliveryTime; 
    }

    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    event ShipmentCreated(address indexed sender, address indexed receiver, uint256 pickupTime, uint256 distance, uint256 price,uint256 estimatedDeliveryTime);
    event ShipmentUpdated(address indexed sender, address indexed receiver, uint256 pickupTime);
    event ShipmentDelivered(address indexed sender, address indexed receiver, uint256 deliveryTime);
    event ShipmentPaid(address indexed sender, address indexed receiver, uint256 amount);

    constructor() {
        shipmentCount = 0;
    }

    function createShipment(address _receiver, uint256 _pickupTime, uint256 _distance, uint256 _price, uint256 _estimatedDeliveryTime
    ) public payable {
        require(msg.value == _price, "Payment amount must match the price");
        Shipment memory shipment = Shipment(
            msg.sender,
            _receiver,
            _pickupTime,
            0,
            _distance,
            _price,
            ShipmentStatus.PENDING,
            false,
            _estimatedDeliveryTime
        );
        shipments[msg.sender].push(shipment);
        shipmentCount++;
        emit ShipmentCreated(msg.sender, _receiver, _pickupTime, _distance, _price, _estimatedDeliveryTime);
    }

    function startShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];

        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.PENDING, "Shipment is not pending");

        shipment.status = ShipmentStatus.IN_TRANSIT;
        emit ShipmentUpdated(_sender, _receiver, shipment.pickupTime);
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

        emit ShipmentDelivered(_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(_sender, _receiver, amount);
    }

    function getShipment(address _sender, uint256 _index) public view returns (
        address, address, uint256, uint256, uint256, uint256, ShipmentStatus, bool, uint256
    ) {
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.deliveryTime,
            shipment.distance,
            shipment.price,
            shipment.status,
            shipment.isPaid,
            shipment.estimatedDeliveryTime
        );
    }

    function getShipmentsCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }
}