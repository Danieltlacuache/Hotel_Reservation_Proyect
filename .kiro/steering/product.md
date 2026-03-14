# Product Overview

High-concurrency hotel reservation system for a hotel chain managing ~5,000 hotels and ~1 million rooms.

## Core Goals
- Prevent double bookings through strong data consistency (ACID guarantees)
- Handle peak traffic surges with low latency for browsing and acceptable latency (few seconds) for reservations
- Support 10% overbooking to account for anticipated cancellations

## MVP Functional Scope
- Hotel & room management (CRUD by authorized staff)
- Dynamic pricing (rates change daily based on occupancy)
- Hotel and room type detail views
- Reservation creation and cancellation
- Reservation history per user
- Idempotent APIs using idempotency keys (e.g., reservation_id) to prevent duplicate bookings

## Key Domain Concepts
- Users reserve a "Room Type" (e.g., King, Standard), not a specific room number. Room assignment happens at check-in.
- Inventory is tracked per room type per date via a `room_type_inventory` table with composite key `(hotel_id, room_type_id, date)`.
- A two-year availability window is maintained.

## Resilience & Cost Optimization Goals
- High availability via RDS Multi-AZ with synchronous replication and automatic failover
- ElastiCache Redis Multi-AZ cluster with automatic failover
- Fault tolerance with DLQs (SQS) for failed reservation attempts
- Cost efficiency through serverless scale-to-zero during low traffic
- Storage optimization with S3 Intelligent-Tiering (archive at 90d, deep archive at 180d)
- Read scaling via ElastiCache to reduce RDS read load by 80%+
- Observability via CloudWatch Log Groups per Lambda (30-day retention)
