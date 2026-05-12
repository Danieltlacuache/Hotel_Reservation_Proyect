# ReservFlow — Hotel Reservation System

## Overview

ReservFlow is a hotel reservation system built as a monolithic Next.js 14 application, deployed on AWS using ECS Fargate with PostgreSQL (RDS) and Redis (ElastiCache). All infrastructure is fully private (no resources exposed to 0.0.0.0/0) and managed via Terraform.

**Docker Image:** `nino200431/reservflow:latest`  
**ALB Endpoint:** `http://reservflow-dev-alb-856383033.us-east-1.elb.amazonaws.com` (restricted to allowed IPs)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 14 (TypeScript, standalone output) |
| Runtime | Node.js 20 Alpine |
| Database | PostgreSQL 15 (AWS RDS) |
| Cache | Redis 7.x (AWS ElastiCache) |
| Compute | AWS ECS Fargate |
| Load Balancer | AWS ALB (IP-restricted) |
| Container Registry | AWS ECR |
| Secrets | AWS Secrets Manager |
| Observability | AWS CloudWatch + SNS |
| Networking | VPC Endpoints (no NAT, no internet) |
| IaC | Terraform |
| Validation | Zod |
| Testing | Vitest + fast-check (property-based) |
| Styling | Tailwind CSS |

---

## System Architecture

```mermaid
graph TB
    subgraph Internet
        User[("👤 User Browser<br/>(IP-restricted)")]
    end

    subgraph AWS["AWS Cloud — us-east-1 (Private)"]

        subgraph VPC["VPC — 10.0.0.0/16"]

            subgraph PublicSubnets["Public Subnets (us-east-1a, us-east-1b)"]
                ALB["Application Load Balancer<br/>Internet-facing<br/>Port 80 (IP-restricted)"]
            end

            subgraph PrivateSubnets["Private Subnets (us-east-1a, us-east-1b)"]

                subgraph ECSCluster["ECS Cluster (Fargate)"]
                    AppService["ECS Service: reservflow<br/>Task: Next.js Container<br/>Port 3000 | 256 CPU | 512 MB"]
                    MigrationTask["Migration Task (one-off)<br/>PostgreSQL Client<br/>Runs SQL migrations + seeds"]
                end

                subgraph DataLayer["Data Layer"]
                    RDS[("RDS PostgreSQL 15<br/>db.t3.micro | 20 GB<br/>Encrypted | Private")]
                    Redis[("ElastiCache Redis 7.x<br/>cache.t3.micro<br/>Encryption in transit")]
                end

                subgraph VPCEndpoints["VPC Endpoints (Private AWS Access)"]
                    ECRA["ECR API"]
                    ECRD["ECR Docker"]
                    S3GW["S3 Gateway"]
                    SME["Secrets Manager"]
                    CWL["CloudWatch Logs"]
                end
            end
        end

        subgraph Supporting["Supporting Services"]
            ECR["ECR Repository<br/>reservflow-dev"]
            SM["Secrets Manager<br/>DATABASE_URL | REDIS_URL"]
            CW["CloudWatch<br/>Logs & Alarms"]
            SNS["SNS Topic<br/>Notifications"]
        end
    end

    User -->|"HTTP :80<br/>(your IP only)"| ALB
    ALB -->|HTTP :3000| AppService
    AppService -->|TCP :5432| RDS
    AppService -->|TCP :6379| Redis
    MigrationTask -->|TCP :5432| RDS

    AppService -.->|Pull image| ECRA
    AppService -.->|Resolve secrets| SME
    AppService -.->|Logs| CWL
    ECRA -.-> ECR
    SME -.-> SM
    CWL -.-> CW
    CW -.->|Alarm| SNS
```

---

## Security Architecture

### No Internet Exposure

- **No NAT Gateway** — private subnets have no route to internet
- **No 0.0.0.0/0** in any security group (ingress or egress)
- **ALB restricted** to specific IP CIDRs (configured in `allowed_cidr_blocks`)
- **VPC Endpoints** replace internet access for AWS services (ECR, S3, Secrets Manager, CloudWatch Logs)

### Security Group Rules

```mermaid
graph LR
    YourIP["Your IP/32"] -->|"TCP 80"| ALBSG["ALB SG"]
    ALBSG -->|"TCP 3000"| ECSSG["ECS Task SG"]
    ECSSG -->|"TCP 5432"| RDSSG["RDS SG"]
    ECSSG -->|"TCP 6379"| ECSG["ElastiCache SG"]
    ECSSG -->|"TCP 443"| VPCE["VPC Endpoints + S3"]

    style ALBSG fill:#8C4FFF,stroke:#232F3E,color:white
    style ECSSG fill:#ED7100,stroke:#232F3E,color:white
    style RDSSG fill:#3B48CC,stroke:#232F3E,color:white
    style ECSG fill:#3B48CC,stroke:#232F3E,color:white
    style VPCE fill:#3B8624,stroke:#232F3E,color:white
```

### SCP Compliance

| Restriction | Status |
|---|---|
| No resources exposed to 0.0.0.0/0 | ✅ |
| Tags: Team="team-7", Name="daniel.guzman@iteso.mx", Owner="daniel.guzman@iteso.mx" | ✅ |
| Region: us-east-1 only | ✅ |
| RDS: db.t3.micro (allowed family) | ✅ |
| No SSH/RDP open | ✅ |
| No S3 via Terraform | ✅ |
| No IAM users with console access | ✅ |

---

## Terraform Module Structure

```mermaid
graph TD
    ROOT["main.tf<br/>(Root Module)"] --> VPC["modules/vpc"]
    ROOT --> ECR["modules/ecr"]
    ROOT --> SECRETS["modules/secrets"]
    ROOT --> OBS["modules/observability"]
    ROOT --> RDS["modules/rds"]
    ROOT --> ELASTI["modules/elasticache"]
    ROOT --> ALB["modules/alb"]
    ROOT --> ECS["modules/ecs"]

    VPC -->|"vpc_id, subnet_ids, sg_ids"| RDS
    VPC -->|"vpc_id, subnet_ids, sg_ids"| ELASTI
    VPC -->|"vpc_id, public_subnet_ids, alb_sg_id"| ALB
    VPC -->|"private_subnet_ids, ecs_task_sg_id"| ECS
    SECRETS -->|"secret_arns"| ECS
    ALB -->|"target_group_arn"| ECS
    ECR -->|"repository_url"| ECS
    OBS -->|"log_group_name"| ECS
    ECS -->|"cluster_name, service_name"| OBS

    style ROOT fill:#232F3E,stroke:#FF9900,color:white
    style VPC fill:#8C4FFF,stroke:#232F3E,color:white
    style ECS fill:#ED7100,stroke:#232F3E,color:white
    style RDS fill:#3B48CC,stroke:#232F3E,color:white
    style ELASTI fill:#3B48CC,stroke:#232F3E,color:white
    style ALB fill:#8C4FFF,stroke:#232F3E,color:white
    style ECR fill:#ED7100,stroke:#232F3E,color:white
    style SECRETS fill:#DD344C,stroke:#232F3E,color:white
    style OBS fill:#FF9900,stroke:#232F3E,color:white
```

### Directory Layout

```
terraform/
├── main.tf              # Root module — orchestrates all modules
├── variables.tf         # Input variables with defaults for dev
├── outputs.tf           # ALB DNS, ECR URL, RDS endpoint
├── environments/
│   ├── dev.tfvars       # Dev environment overrides
│   └── prod.tfvars      # Production environment overrides
└── modules/
    ├── vpc/             # VPC, subnets, VPC Endpoints, security groups
    ├── ecs/             # ECS cluster, service, task definitions, IAM
    ├── rds/             # PostgreSQL instance, subnet group
    ├── elasticache/     # Redis replication group, subnet group
    ├── alb/             # Load balancer, target group, listeners
    ├── ecr/             # Container registry, lifecycle policy
    ├── secrets/         # Secrets Manager (DB URL, Redis URL, RDS password)
    └── observability/   # CloudWatch log group, alarms, SNS
```

---

## Deployment Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant ECR as ECR Registry
    participant ECS as ECS Fargate
    participant ALB as Load Balancer
    participant RDS as PostgreSQL

    Note over Dev,RDS: Initial Setup (one-time)
    Dev->>Dev: terraform apply
    Dev->>ECR: docker pull → tag → push (reservflow:latest)
    Dev->>ECR: docker build → push (reservflow:migration)
    Dev->>ECS: Run Migration Task
    ECS->>RDS: Execute SQL migrations + seeds
    RDS-->>ECS: Schema + data created ✓

    Note over Dev,ALB: Application Access
    Dev->>ALB: HTTP from allowed IP
    ALB->>ECS: Forward to container :3000
    ECS-->>Dev: Application responds ✓
```

---

## Quick Start

```bash
# 1. Initialize and deploy infrastructure
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars" -var="db_password=YOUR_PASSWORD"
terraform apply -var-file="environments/dev.tfvars" -var="db_password=YOUR_PASSWORD"

# 2. Push app image to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 311141527383.dkr.ecr.us-east-1.amazonaws.com
docker pull nino200431/reservflow:latest
docker tag nino200431/reservflow:latest 311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev:latest
docker push 311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev:latest

# 3. Build and push migration image
cd ../database
docker build --platform linux/amd64 --provenance=false -t 311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev:migration .
docker push 311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev:migration

# 4. Run database migrations
cd ../terraform
aws ecs run-task --cluster reservflow-dev --task-definition reservflow-dev-migration --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[SUBNET_ID],securityGroups=[SG_ID],assignPublicIp=DISABLED}" --region us-east-1

# 5. Access the application (from allowed IP only)
# http://reservflow-dev-alb-856383033.us-east-1.elb.amazonaws.com
```

---

## Application Components

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/reservations` | Create a reservation |
| GET | `/api/reservations` | List reservations (filterable) |
| GET | `/api/reservations/:id` | Get reservation by ID |
| PATCH | `/api/reservations/:id` | Update reservation status |
| DELETE | `/api/reservations/:id` | Cancel reservation |
| GET | `/api/rooms/availability` | Check room availability |
| GET | `/api/admin/dashboard` | Admin dashboard data |

### Database Schema

| Table | Purpose |
|-------|---------|
| `rooms` | Room catalog (type, capacity, price, active status) |
| `guests` | Guest records (name, email unique, phone) |
| `reservations` | Booking lifecycle with status enum (Pendiente → Confirmada → Completada/Cancelada) |
| `room_inventory` | Availability by room type and date (source of truth) |

---

## Environment Variables

| Variable | Description | Source |
|----------|-------------|--------|
| `DATABASE_URL` | PostgreSQL connection string (with sslmode=no-verify) | Secrets Manager |
| `REDIS_URL` | Redis connection URL (rediss:// for TLS) | Secrets Manager |
| `NODE_ENV` | Runtime environment | Task definition (plaintext) |

---

## AWS Account Info

- **Account:** 311141527383
- **Region:** us-east-1
- **Team:** team-7
- **Contact:** daniel.guzman@iteso.mx
- **Docker Hub:** nino200431
- **SSO Portal:** https://joalgama.awsapps.com/start/#/

---

## Project Documentation

| Document | Location |
|----------|----------|
| OpenAPI Spec | `openapi.yaml` |
| Architecture Context | `docs/reservflow-project-context.md` |
| Mermaid Diagrams | `docs/ecs-fargate-architecture.md` |
| Functional & Non-Functional Requirements | `documentation/FR & NFR.MD` |
| ADR Records | `documentation/ADR_Records.MD` |
| C4 Model Diagrams | `documentation/C4_Model_Diagrams.MD` |
| Test Plan | `documentation/Test_Plan.MD` |
