// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRental {
    struct Property {
        address owner;
        uint256 rent;
        uint256 deposit;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 paidUntil;
        bool active;
    }

    mapping(uint256 => Property) public properties;
    uint256 public numProperties;

    event PropertyCreated(address indexed owner, uint256 indexed propertyId);
    event RentPaid(address indexed tenant, uint256 indexed propertyId, uint256 amount);
    event RentalEnded(address indexed tenant, uint256 indexed propertyId);

    function createProperty(uint256 rent, uint256 deposit, uint256 startTimestamp, uint256 endTimestamp) external {
        require(rent > 0, "Rent must be greater than zero");
        require(deposit > 0, "Deposit must be greater than zero");
        require(startTimestamp > block.timestamp, "Start time must be in the future");
        require(endTimestamp > startTimestamp, "End time must be after start time");

        uint256 propertyId = numProperties;
        properties[propertyId] = Property({
            owner: msg.sender,
            rent: rent,
            deposit: deposit,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            paidUntil: startTimestamp,
            active: true
        });
        numProperties++;

        emit PropertyCreated(msg.sender, propertyId);
    }

    function payRent(uint256 propertyId) external payable {
        Property storage property = properties[propertyId];
        require(property.active, "Property is not active");
        require(msg.value >= property.rent, "Insufficient payment amount");

        uint256 amountToRefund = msg.value - property.rent;
        if (amountToRefund > 0) {
            payable(msg.sender).transfer(amountToRefund);
        }
        payable(property.owner).transfer(property.rent);
        property.paidUntil = property.paidUntil + 30 days;

        emit RentPaid(msg.sender, propertyId, msg.value);
    }

    function endRental(uint256 propertyId) external {
        Property storage property = properties[propertyId];
        require(property.active, "Property is not active");
        require(msg.sender == property.owner || msg.sender == address(this), "Only owner or contract can end rental");

        property.active = false;
        payable(msg.sender).transfer(property.deposit + (property.paidUntil - block.timestamp) * property.rent / 30 days);

        emit RentalEnded(msg.sender, propertyId);
    }
}
