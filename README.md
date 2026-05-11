# ReservFlow — Hotel Reservation System

## Overview

ReservFlow is a hotel reservation system built as a monolithic Next.js 14 application, deployed on AWS using ECS Fargate with PostgreSQL (RDS) and Redis (ElastiCache). Infrastructure is fully managed via Terraform.

**Docker Image:** `nino200431/reservflow:latest`

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 14 (TypeScript, standalone output) |
| Runtime | Node.js 20 Alpine |
| Database | PostgreSQL 15 (AWS RDS) |
| Cache | Redis 7.x (AWS ElastiCache) |
| Compute | AWS ECS Fargate |
| CDN | AWS CloudFront |
| Load Balancer | AWS ALB |
| Container Registry | AWS ECR |
| Secrets | AWS Secrets Manager |
| Observability | AWS CloudWatch + SNS |
| IaC | Terraform |
| Validation | Zod |
| Testing | Vitest + fast-check (property-based) |
| Styling | Tailwind CSS |

---

## System Architecture

```mermaid
graph TB
    subgraph Internet
        User[("👤 User Browser")]
    end

    subgraph AWS["AWS Cloud — us-east-1"]
        
        subgraph CF["CloudFront (Edge)"]
            CDN["CloudFront Distribution<br/>PriceClass_100<br/>HTTP → HTTPS redirect"]
        end

        subgraph VPC["VPC — 10.0.0.0/16"]
            
            subgraph PublicSubnets["Public Subnets (us-east-1a, us-east-1b)"]
                ALB["Application Load Balancer<br/>Internet-facing<br/>Port 80/443"]
                NAT["NAT Gateway<br/>+ Elastic IP"]
                IGW["Internet Gateway"]
            end

            subgraph PrivateSubnets["Private Subnets (us-east-1a, us-east-1b)"]
                
                subgraph ECSCluster["ECS Cluster (Fargate)"]
                    AppService["ECS Service: reservflow<br/>Task: Next.js Container<br/>Port 3000 | 256 CPU | 512 MB"]
                    MigrationTask["Migration Task (one-off)<br/>PostgreSQL Client<br/>Runs SQL migrations"]
                end

                subgraph DataLayer["Data Layer"]
                    RDS[("RDS PostgreSQL 15<br/>db.t3.micro | 20 GB<br/>Encrypted | Private")]
                    Redis[("ElastiCache Redis 7.x<br/>cache.t3.micro<br/>Encryption in transit")]
                end
            end
        end

        subgraph Supporting["Supporting Services"]
            ECR["ECR Repository<br/>reservflow"]
            SM["Secrets Manager<br/>DATABASE_URL | REDIS_URL"]
            CW["CloudWatch<br/>Logs & Alarms"]
            SNS["SNS Topic<br/>Notifications"]
        end
    end

    User -->|HTTPS| CDN
    CDN -->|HTTP :80| ALB
    ALB -->|HTTP :3000| AppService
    AppService -->|TCP :5432| RDS
    AppService -->|TCP :6379| Redis
    MigrationTask -->|TCP :5432| RDS

    AppService -.->|Pull image| ECR
    AppService -.->|Resolve secrets| SM
    MigrationTask -.->|Resolve secrets| SM
    AppService -.->|Logs| CW
    CW -.->|Alarm| SNS
    PrivateSubnets -.->|Outbound| NAT
    NAT -.->|Internet| IGW
```

---

## Security Group Rules

```mermaid
graph LR
    Internet2["0.0.0.0/0"] -->|"TCP 80, 443"| ALBSG["ALB SG"]
    ALBSG -->|"TCP 3000"| ECSSG["ECS Task SG"]
    ECSSG -->|"TCP 5432"| RDSSG["RDS SG"]
    ECSSG -->|"TCP 6379"| ECSG["ElastiCache SG"]

    style ALBSG fill:#8C4FFF,stroke:#232F3E,color:white
    style ECSSG fill:#ED7100,stroke:#232F3E,color:white
    style RDSSG fill:#3B48CC,stroke:#232F3E,color:white
    style ECSG fill:#3B48CC,stroke:#232F3E,color:white
```

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
    ROOT --> CFRONT["modules/cloudfront"]

    VPC -->|"vpc_id, subnet_ids, sg_ids"| RDS
    VPC -->|"vpc_id, subnet_ids, sg_ids"| ELASTI
    VPC -->|"vpc_id, public_subnet_ids, alb_sg_id"| ALB
    VPC -->|"private_subnet_ids, ecs_task_sg_id"| ECS
    SECRETS -->|"secret_arns"| ECS
    ALB -->|"target_group_arn"| ECS
    ALB -->|"alb_dns_name"| CFRONT
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
    style CFRONT fill:#8C4FFF,stroke:#232F3E,color:white
    style SECRETS fill:#DD344C,stroke:#232F3E,color:white
    style OBS fill:#FF9900,stroke:#232F3E,color:white
```

### Directory Layout

```
terraform/
├── main.tf              # Root module — orchestrates all modules
├── variables.tf         # Input variables with defaults for dev
├── outputs.tf           # ALB DNS, CloudFront domain, ECR URL, RDS endpoint
├── environments/
│   ├── dev.tfvars       # Dev environment overrides
│   └── prod.tfvars      # Production environment overrides
└── modules/
    ├── vpc/             # VPC, subnets, NAT, security groups
    ├── ecs/             # ECS cluster, service, task definitions, IAM
    ├── rds/             # PostgreSQL instance, subnet group
    ├── elasticache/     # Redis replication group, subnet group
    ├── alb/             # Load balancer, target group, listeners
    ├── ecr/             # Container registry, lifecycle policy
    ├── cloudfront/      # CDN distribution
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
    participant CF as CloudFront
    participant RDS as PostgreSQL

    Note over Dev,RDS: Initial Setup (one-time)
    Dev->>ECR: docker push reservflow:latest
    Dev->>ECS: Run Migration Task
    ECS->>RDS: Execute SQL migrations (001-004)
    RDS-->>ECS: Schema created ✓

    Note over Dev,CF: Application Deployment
    Dev->>ECS: Update task definition (new image tag)
    ECS->>ECR: Pull container image
    ECS->>ECS: Launch new task (rolling update)
    ECS->>ALB: Register healthy target
    ALB->>CF: Origin responds
    CF-->>Dev: Application live ✓
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

### Core Modules

| Module | Responsibility |
|--------|---------------|
| `src/modules/reservations/` | Reservation lifecycle (create, modify, cancel, status transitions) |
| `src/modules/inventory/` | Room availability with Redis cache-first strategy |
| `src/modules/integrations/` | External platform adapters (extensible) |
| `src/components/` | React UI — search, booking funnel, admin dashboard |

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
| `DATABASE_URL` | PostgreSQL connection string | Secrets Manager |
| `REDIS_URL` | Redis connection URL | Secrets Manager |
| `NODE_ENV` | Runtime environment | Task definition (plaintext) |

---

## AWS Account Constraints (SCP)

- **Region:** us-east-1 only
- **Tags (mandatory):** `Team = "team-7"`, `Name = "daniel.guzman@iteso.mx"`
- **RDS:** db.t2, db.t3, db.t4g families only
- **No open ports:** SSH/RDP to 0.0.0.0/0 blocked
- **No S3 via Terraform:** Buckets must be created via Console
- **Terraform provider:** Uses `default_tags` for automatic tag propagation

---

## Quick Start

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan for dev environment
terraform plan -var-file=environments/dev.tfvars

# Apply infrastructure
terraform apply -var-file=environments/dev.tfvars

# Push Docker image to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-url>
docker tag nino200431/reservflow:latest <ecr-url>/reservflow:latest
docker push <ecr-url>/reservflow:latest

# Run database migrations (one-off ECS task)
aws ecs run-task \
  --cluster reservflow \
  --task-definition reservflow-migration \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<private-subnet>],securityGroups=[<ecs-sg>]}"
```

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
| Quality Reports | `documentation/Quality_Final_Report.MD` |

---

## Team

- **Team:** team-7
- **Contact:** daniel.guzman@iteso.mx
- **AWS Account:** 311141527383
- **Docker Hub:** nino200431
