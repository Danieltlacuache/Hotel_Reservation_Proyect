# Technology Stack

## Cloud & Infrastructure
- Cloud provider: AWS
- IaC / Deployment: CloudFormation (managed via Kiro)
- Target services: ALB, Lambda, RDS, ElastiCache (Redis), S3, CloudFront, SQS, CloudWatch

## Architecture
- Microservices pattern with stateless Lambda functions in private subnets
- Services: Hotel Service (512MB), Rate Service (256MB), Reservation Service (512MB)
- Application Load Balancer (ALB) in public subnets as entry point with path-based routing
- All ALB-to-Lambda traffic stays within the VPC

## Data Layer
- Primary store: Amazon RDS PostgreSQL 16.4 (db.r6g.xlarge, 600GB gp3, 12K IOPS, Multi-AZ)
- Cache: Amazon ElastiCache Redis 7.1 (cache.r6g.large, Multi-AZ cluster)
- Static assets: S3 (Intelligent-Tiering) + CloudFront CDN (OAC)

## Concurrency Strategies
- Pessimistic locking (`SELECT ... FOR UPDATE`) for critical reservation paths
- Optimistic locking via version columns as an alternative
- `CHECK` constraints to enforce `total_reserved <= total_inventory`
- Redis cache to reject ineligible requests before hitting RDS

## Database Scaling
- Sharding by `hotel_id` so all data for a hotel lives on one shard

## Resilience & Fault Tolerance
- RDS Multi-AZ with synchronous replication for automatic failover
- ElastiCache Redis Multi-AZ with automatic failover
- Lambda Dead Letter Queues (Amazon SQS) for failed reservation retries
- ElastiCache reduces RDS read operations by 80%+, sub-millisecond latency

## Cost Optimization
- Serverless (Lambda + ALB) scales to zero during low traffic
- S3 Intelligent-Tiering for infrequently accessed hotel images (archive at 90d, deep archive at 180d)
- ElastiCache offloads expensive RDS reads

## Observability
- CloudWatch Log Groups per Lambda function (30-day retention)
- RDS Performance Insights enabled

## Security
- IAM roles per service with least-privilege policies
- Lambda functions in private subnets, ALB in public subnets
- Security groups restrict traffic: ALB→Lambda, Lambda→RDS (5432), Lambda→Redis (6379)
- S3 bucket fully private, accessed via CloudFront OAC

## Commands
No build/test/deploy commands are established yet. This section should be updated as the project scaffolds out.
