# ReservFlow — Infrastructure Report

## 1. Architecture Overview

ReservFlow follows a **monolithic containerized architecture** deployed on AWS ECS Fargate. The application is a single Next.js 14 container that handles both frontend (SSR) and backend (API routes) in one process, backed by PostgreSQL for persistence and Redis for caching.

### Design Pattern: Monolith-in-a-Container

Unlike microservices, ReservFlow packages everything into a single Docker image. This simplifies deployment and reduces operational overhead while still benefiting from container orchestration (ECS Fargate manages the container lifecycle, health checks, and rolling deployments).

The architecture follows the **Cache-Aside pattern** for room availability: the app checks Redis first, and only queries PostgreSQL on cache miss. This reduces database load for the most frequent read operation (availability checks).

### Architecture Layers (4 Layers)

The system is organized in **4 distinct layers**:

| Layer | Components | Responsibility |
|-------|-----------|---------------|
| **1. Edge / Access Layer** | ALB (IP-restricted) | Traffic ingress, health checks, load distribution |
| **2. Compute Layer** | ECS Fargate (Next.js container) | Application logic, SSR rendering, API routes |
| **3. Cache Layer** | ElastiCache Redis | Cache-Aside for availability, session-like data, reduces DB load |
| **4. Persistence Layer** | RDS PostgreSQL | Source of truth for rooms, guests, reservations, inventory |

Supporting cross-cutting concerns:
- **Networking**: VPC + VPC Endpoints (private connectivity to AWS services)
- **Security**: Secrets Manager (credential injection), Security Groups (least-privilege network access)
- **Observability**: CloudWatch Logs + Metric Alarms + SNS notifications
- **Registry**: ECR (container image storage and distribution)

---

## 2. AWS Services and Their Roles

### ECS Fargate (Compute)

- Runs the Next.js container without managing servers
- **No auto-scaling configured** — currently runs 1 task (256 CPU / 512 MB memory)
- Rolling deployments: minimum 100% healthy, maximum 200% during deploy
- For production, you would add `aws_appautoscaling_target` and `aws_appautoscaling_policy` to scale based on CPU/memory utilization

### ECR (Container Registry)

- Stores Docker images privately within AWS
- ECS pulls images from ECR via VPC Endpoint (no internet required)
- Lifecycle policy retains only the last 10 untagged images to control storage costs
- **Flow**: Developer pulls from Docker Hub → tags for ECR → pushes to ECR → ECS pulls from ECR

### ALB (Application Load Balancer)

- Routes HTTP traffic to ECS tasks on port 3000
- Health checks at `/` every 30 seconds
- **IP-restricted**: Only allows traffic from configured CIDR blocks (no 0.0.0.0/0)
- Currently no HTTPS (no ACM certificate configured for dev)
- For horizontal scaling, ALB would distribute traffic across multiple ECS tasks

### RDS PostgreSQL (Database)

- db.t3.micro instance with 20 GB encrypted storage
- Private subnet only — no public access
- SSL required for connections (`sslmode=no-verify` in the app's connection string)
- Stores: rooms, guests, reservations, room_inventory tables
- Backup retention: 7 days

### ElastiCache Redis (Cache)

- cache.t3.micro with transit encryption enabled
- **Purpose**: Cache-Aside pattern for room availability
  - On search: app checks Redis first → if miss, queries PostgreSQL → caches result in Redis
  - On reservation confirmation: inventory decremented in both Redis and PostgreSQL
  - On cancellation: inventory incremented back
- **Important**: If Redis has stale data, the app shows incorrect availability. A `FLUSHALL` resets the cache.

### Secrets Manager

- Stores sensitive connection strings that ECS injects at task launch via `valueFrom`
- Secrets stored:
  - `DATABASE_URL` — PostgreSQL connection string (with sslmode=no-verify)
  - `REDIS_URL` — Redis connection URL (rediss:// for TLS)
  - `rds-password` — RDS master password
- **Why not environment variables?** Secrets Manager keeps credentials out of task definitions and Terraform state. ECS resolves them at runtime.

### VPC Endpoints (Private Networking)

- Replace NAT Gateway — no internet access from private subnets
- 5 endpoints configured:
  - `ecr.api` (Interface) — ECS authenticates with ECR
  - `ecr.dkr` (Interface) — ECS pulls image layers
  - `s3` (Gateway) — ECR stores layers in S3
  - `secretsmanager` (Interface) — ECS resolves secrets at task launch
  - `logs` (Interface) — ECS sends logs to CloudWatch
- **Cost benefit**: VPC Endpoints have a fixed monthly cost vs NAT Gateway which charges per GB of data transferred

### CloudWatch (Observability)

- Log group `/ecs/reservflow-dev` with 14-day retention
- 3 alarms configured:
  - CPU utilization > 80%
  - Memory utilization > 80%
  - Unhealthy host count > 0
- Alarm actions send to SNS topic (if configured)

---

## 3. Scalability

### Current State (Dev)

- **Horizontal scaling**: NOT configured. Single ECS task.
- **Vertical scaling**: Task CPU/memory configurable via Terraform variables.

### What Would Be Needed for Production

```hcl
# Auto-scaling target
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${cluster_name}/${service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale on CPU
resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

The ALB already supports multiple targets — adding auto-scaling would distribute traffic across 1-4 tasks automatically.

---

## 4. Security Model

### Zero Internet Exposure

| Layer | Protection |
|-------|-----------|
| ALB ingress | Restricted to specific IP CIDR (not 0.0.0.0/0) |
| ECS egress | Only to VPC CIDR + S3 prefix list (port 443) |
| RDS | Private subnet, no public access, SSL required |
| Redis | Private subnet, transit encryption enabled |
| VPC Endpoints | Replace internet access for AWS services |
| Secrets | Never in plaintext — resolved at runtime by ECS |

### SCP Compliance

All resources tagged with:
- `Team = "team-7"`
- `Name = "daniel.guzman@iteso.mx"`
- `Owner = "daniel.guzman@iteso.mx"`

---

## 5. Known Bug: Reservation Creation Fails (400 Bad Request)

### Symptom

When a user selects a room and fills in guest data, the reservation fails with:
```json
{"error": {"code": "VALIDATION_ERROR", "message": "Datos de entrada inválidos", "details": [{"field": "roomId", "message": "Invalid UUID"}]}}
```

### Root Cause

The frontend component `ReservationFunnel.tsx` uses a **hardcoded placeholder UUID**:
```typescript
roomId: '00000000-0000-0000-0000-000000000001'
```

This UUID is not RFC 4122 compliant (version 4 UUIDs require specific bits in positions 13 and 17). Zod's `z.string().uuid()` validator rejects it.

Additionally, even if the UUID format were valid, it doesn't correspond to any real room in the database. The `rooms` table uses `gen_random_uuid()` which generates random UUIDs.

### Design Flaw

The availability API (`GET /api/rooms/availability`) returns `roomType` and `availableCount` but **not** individual `roomId` values. The frontend has no way to obtain a real `roomId` to send in the reservation request.

The correct fix would be:
1. The availability API should return available `roomId` values (or a separate endpoint to get a room by type)
2. The frontend should use a real `roomId` from the API response

### Temporary Hack (if needed)

Insert a room with a valid UUID that the frontend can use:
```sql
INSERT INTO rooms (id, type, capacity, price_per_night, is_active)
VALUES ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'single', 1, 800.00, true);
```

Then update the frontend placeholder to use `'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'`. However, this requires rebuilding the Docker image.

### Impact

- Room search and availability: ✅ Works correctly
- Admin dashboard: ✅ Works correctly
- Reservation creation: ❌ Blocked by this bug
- Reservation listing: ✅ Works (returns empty since no reservations can be created)

---

## 6. Deployment Workflow

```
1. terraform apply          → Creates all AWS infrastructure
2. docker pull/tag/push     → Pushes app image to ECR (reservflow-dev:latest)
3. docker build/push        → Pushes migration image to ECR (reservflow-dev:migration)
4. aws ecs run-task         → Runs migration task (creates DB schema + seeds)
5. aws ecs run-task (fix)   → Runs fix task (flushes Redis cache)
6. Access via ALB DNS       → http://reservflow-dev-alb-856383033.us-east-1.elb.amazonaws.com
```

### Updating the Application

```
1. docker pull nino200431/reservflow:latest
2. docker tag → 311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev:latest
3. docker push
4. aws ecs update-service --force-new-deployment
```

ECS performs a rolling update — launches new task, waits for health check, drains old task.

---

## 7. Cost Considerations (Dev Environment)

| Service | Approximate Monthly Cost |
|---------|------------------------|
| ECS Fargate (1 task, 256 CPU, 512 MB) | ~$9 |
| RDS db.t3.micro | ~$15 |
| ElastiCache cache.t3.micro | ~$12 |
| ALB | ~$16 + $0.008/LCU-hour |
| VPC Endpoints (5 Interface) | ~$36 (5 × $7.20) |
| NAT Gateway (eliminated) | $0 (saved ~$32) |
| ECR storage | < $1 |
| CloudWatch | < $1 |
| **Total estimate** | **~$90/month** |

The VPC Endpoints are the most expensive component but are required by the SCP restriction (no internet exposure). In a production environment with NAT Gateway allowed, you could replace the 4 Interface endpoints with a single NAT Gateway (~$32) and save ~$4/month.

---

## 8. Lessons Learned

1. **SCP restrictions require the `Owner` tag** — not documented in the student guide, discovered via `aws sts decode-authorization-message`
2. **`sslmode=no-verify`** is a Node.js `pg` library parameter, not a libpq/psql parameter — migration tasks using `psql` need `sslmode=require` instead
3. **Redis cache must be flushed** after seeding the database — stale cache shows 0 availability even when DB has correct data
4. **ECS Exec requires `ssmmessages` VPC Endpoint** — without it, `execute-command` fails with TargetNotConnected
5. **Terraform `default_tags`** propagates to most resources but should be verified with `terraform plan` for IAM resources
6. **RDS engine versions** change over time — `15.4` was deprecated, had to use `15.13`
7. **PowerShell escaping** makes inline JSON overrides nearly impossible — always use `file://` with a JSON file
