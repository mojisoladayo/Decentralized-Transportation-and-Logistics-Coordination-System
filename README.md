# Decentralized Transportation and Logistics Coordination System

A comprehensive blockchain-based solution for managing transportation and logistics operations using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that handle different aspects of transportation and logistics:

### 1. Freight Shipping and Tracking Contract (`freight-shipping.clar`)
- Manages cargo shipments with unique tracking IDs
- Provides real-time location updates and status tracking
- Handles shipping cost calculations and payment processing
- Maintains shipment history and delivery confirmations

### 2. Last-Mile Delivery Optimization Contract (`last-mile-delivery.clar`)
- Coordinates efficient package delivery routes
- Manages delivery scheduling and time windows
- Tracks delivery attempts and success rates
- Optimizes driver assignments based on location and capacity

### 3. Fleet Management and Maintenance Contract (`fleet-management.clar`)
- Tracks vehicle information, maintenance schedules, and performance
- Monitors fuel consumption and operational costs
- Manages driver assignments and performance metrics
- Schedules preventive maintenance and repairs

### 4. Warehouse Inventory and Fulfillment Contract (`warehouse-inventory.clar`)
- Manages inventory levels across multiple warehouse locations
- Handles order fulfillment and stock allocation
- Tracks product movements and storage optimization
- Manages supplier relationships and restocking

### 5. International Shipping Documentation Contract (`international-shipping.clar`)
- Handles customs forms and documentation
- Manages import/export permits and compliance
- Tracks international shipping regulations
- Maintains trade compliance records

## Key Features

- **Decentralized Tracking**: All shipments and deliveries are tracked on-chain
- **Automated Payments**: Smart contract-based payment processing
- **Real-time Updates**: Location and status updates stored immutably
- **Compliance Management**: Automated regulatory compliance checking
- **Performance Analytics**: On-chain metrics for optimization
- **Multi-party Coordination**: Seamless interaction between shippers, carriers, and receivers

## Data Structures

### Shipment
- Shipment ID, origin, destination
- Weight, dimensions, value
- Current location and status
- Estimated delivery time

### Vehicle
- Vehicle ID, type, capacity
- Current location and availability
- Maintenance history and schedule
- Fuel consumption metrics

### Inventory Item
- Product ID, quantity, location
- Supplier information
- Reorder levels and thresholds
- Storage requirements

## Contract Interactions

The contracts work together to provide a complete logistics solution:
1. Orders are created in the warehouse contract
2. Freight shipping contract handles long-distance transport
3. Fleet management assigns vehicles and drivers
4. Last-mile delivery handles final delivery
5. International shipping manages cross-border documentation

## Getting Started

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Deploy contracts using Clarinet: `clarinet deploy`

## Testing

The system includes comprehensive tests for all contract functions using Vitest. Tests cover:
- Contract deployment and initialization
- Core functionality of each contract
- Error handling and edge cases
- Integration between contracts

## Security Considerations

- All functions include proper access controls
- Input validation prevents invalid data entry
- State changes are atomic and consistent
- Emergency pause functionality for critical issues
  
