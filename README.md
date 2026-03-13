# Project Overview

This project focuses on the design and implementation of a high-concurrency hotel reservation system for a hotel chain managing approximately 5,000 hotels and 1 million rooms. The primary goal is to ensure high data consistency to prevent double bookings while maintaining low latency and high availability. This repository is developed using Kiro for infrastructure management and deployment on AWS.

---

## SDLC Phase 1: Requirements Gathering and Analysis

### Functional Requirements (MVP Scope)

- **Hotel Management:** Authorized staff can add, remove, and update hotel and room information.
- **Inventory and Pricing:** Support for dynamic pricing where rates change daily based on occupancy.
- **View Details:** Users can view detailed information about hotels and specific room types.
- **Reservation Management:** Users can create and cancel reservations.
- **Overbooking Support:** The system is designed to allow 10% overbooking to account for anticipated cancellations.
- **Reservation History:** Users can view their past reservation records.

### Non-Functional Requirements

- **High Concurrency:** The system must handle peak traffic surges where many customers try to book the same room simultaneously.
- **Data Consistency:** The system must provide ACID guarantees to ensure no two customers book the same room for the same date.
- **Moderate Latency:** It is acceptable if processing a reservation takes a few seconds, but response times for browsing should be fast.
- **Idempotency:** APIs must handle retries gracefully using idempotency keys (e.g., `reservation_id`) to prevent duplicate bookings.

---

## SDLC Phase 2: System Design

### Architecture Overview (AWS & Kiro)

The system employs a microservices architecture to decouple core business logic. Kiro is used to orchestrate the following AWS components:

- **AWS API Gateway:** Acts as the entry point for all requests, handling authentication, rate limiting, and routing to specific microservices.
- **AWS Lambda:** Hosts stateless microservices including the Hotel Service, Rate Service, and Reservation Service.
- **Amazon RDS (PostgreSQL/MySQL):** Serves as the primary relational data store to manage transactional integrity and ACID properties.
- **Amazon ElastiCache (Redis):** Implements an inventory cache layer to reduce database load and speed up availability checks.
- **Amazon S3 & CloudFront:** Manages and distributes static assets like hotel images with low latency via a CDN.

### Data Model Design

The system utilizes a relational database because it works well with read-heavy workflows and provides strong consistency.

- **Room-Type Level Reservation:** Users reserve a "Room Type" (e.g., King, Standard) rather than a specific room number, which is assigned at check-in.
- **Inventory Management:** The `room_type_inventory` table stores availability data per date for a two-year window.
- **Primary Key:** A composite key of `(hotel_id, room_type_id, date)` is used for the inventory table.
- **Database Sharding:** To handle massive scale, the database can be sharded by `hotel_id`, ensuring all data for a specific hotel resides on the same shard.

### Concurrency and Consistency Strategies

To resolve race conditions during peak booking times, the following strategies are considered:

- **Pessimistic Locking:** Uses database-level row locks (e.g., `SELECT ... FOR UPDATE`) to prevent simultaneous updates.
- **Optimistic Locking:** Uses version numbers to ensure a row has not changed between reading and writing.
- **Database Constraints:** A `CHECK` constraint is applied to ensure `total_reserved` never exceeds the allowed `total_inventory`.
- **Inventory Caching:** Redis tracks available room counts; while the database remains the source of truth, the cache blocks most ineligible requests before they reach the RDS.

---

## Technology Stack Summary

| Component        | Technology                        |
|------------------|-----------------------------------|
| Cloud Provider   | AWS                               |
| IaC / Deployment | Kiro                              |
| Database         | Relational (RDS) + Caching (Redis)|
| Architecture     | Microservices (Lambda, API Gateway)|
