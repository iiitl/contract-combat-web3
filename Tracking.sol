// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tracking {
    // Using an enum for shipment status makes the code easier to read.
    enum ShipmentStatus { Pending, InTransit, Delivered }

    struct Shipment {
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 estimatedDeliveryTime; // New: estimated delivery time for the shipment
        uint256 deliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status;
        bool isPaid;
    }

    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    event ShipmentCreated(
        address indexed sender,
        address indexed receiver,
        uint256 pickupTime,
        uint256 estimatedDeliveryTime,
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

    constructor() {
        shipmentCount = 0;
    }

    // Now requires an additional _estimatedDeliveryTime parameter.
    function createShipment(
        address _receiver,
        uint256 _pickupTime,
        uint256 _estimatedDeliveryTime,
        uint256 _distance,
        uint256 _price
    ) public payable {
        require(msg.value == _price, "Payment amount must match the price");
        Shipment memory shipment = Shipment({
            sender: msg.sender,
            receiver: _receiver,
            pickupTime: _pickupTime,
            estimatedDeliveryTime: _estimatedDeliveryTime,
            deliveryTime: 0,
            distance: _distance,
            price: _price,
            status: ShipmentStatus.Pending,
            isPaid: false
        });
        shipments[msg.sender].push(shipment);
        shipmentCount++;
        emit ShipmentCreated(msg.sender, _receiver, _pickupTime, _estimatedDeliveryTime, _distance, _price);
    }

    function startShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];
        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.Pending, "Shipment is not pending");

        shipment.status = ShipmentStatus.InTransit;
        emit ShipmentUpdated(_sender, _receiver, shipment.pickupTime);
    }

    function completeShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];
        require(shipment.receiver == _receiver, "Invalid receiver.");
        require(shipment.status == ShipmentStatus.InTransit, "Shipment is not in transit");
        require(!shipment.isPaid, "Shipment already paid");

        shipment.status = ShipmentStatus.Delivered;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount);
        shipment.isPaid = true;

        emit ShipmentDelivered(_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(_sender, _receiver, amount);
    }

    function getShipment(address _sender, uint256 _index) public view returns (
        address, address, uint256, uint256, uint256, uint256, ShipmentStatus, bool
    ) {
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.estimatedDeliveryTime,
            shipment.deliveryTime,
            shipment.distance,
            shipment.status,
            shipment.isPaid
        );
    }

    function getShipmentsCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }
}
