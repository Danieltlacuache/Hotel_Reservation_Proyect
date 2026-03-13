# Technology Stack

## Cloud & Infrastructure
- Cloud provider: AWS
- IaC / Deployment: AWS CDK (managed via Kiro)
- Target services: API Gateway, Lambda, RDS, ElastiCache (Redis), S3, CloudFront

## Architecture
- Microservices pattern with stateless Lambda functions
- Services: Hotel Service, Rate Service, Reservation Service
- API Gateway as single entry point (auth, rate limiting, routing)

## Data Layer
- Primary store: Amazon RDS (PostgreSQL or MySQL) — relational, ACID-compliant
- Cache: Amazon ElastiCache (Redis) — inventory availability cache
- Static assets: S3 + CloudFront CDN

## Concurrency Strategies
- Pessimistic locking (`SELECT ... FOR UPDATE`) for critical reservation paths
- Optimistic locking via version columns as an alternative
- `CHECK` constraints to enforce `total_reserved <= total_inventory`
- Redis cache to reject ineligible requests before hitting RDS

## Database Scaling
- Sharding by `hotel_id` so all data for a hotel lives on one shard

## Commands
No build/test/deploy commands are established yet. This section should be updated as the project scaffolds out.
