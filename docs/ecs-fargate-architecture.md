# ReservFlow — ECS Fargate Infrastructure Architecture (Private)

## Key Design Decisions

- **No NAT Gateway** — VPC Endpoints replace internet access for AWS services
- **No 0.0.0.0/0** — ALB restricted to specific IP CIDRs only
- **No CloudFront** — direct ALB access from allowed IPs
- **VPC Endpoints** for ECR API, ECR Docker, S3 (Gateway), Secrets Manager, CloudWatch Logs
- **All egress restricted** to VPC CIDR + S3 prefix list (no internet)

## System Architecture

```mermaid
graph TB
    subgraph Internet
        User[("👤 User Browser<br/>(IP-restricted)")]
    end

    subgraph AWS["AWS Cloud — us-east-1 (Fully Private)"]

        subgraph VPC["VPC — 10.0.0.0/16"]

            subgraph PublicSubnets["Public Subnets (us-east-1a, us-east-1b)"]
                ALB["Application Load Balancer<br/>Internet-facing<br/>Port 80 (IP-restricted only)"]
                IGW["Internet Gateway"]
            end

            subgraph PrivateSubnets["Private Subnets (us-east-1a, us-east-1b)"]

                subgraph ECSCluster["ECS Cluster (Fargate)"]
                    AppService["ECS Service: reservflow<br/>Next.js Container :3000<br/>256 CPU | 512 MB<br/>Auto-scaling: 1-3 tasks (CPU 70%)"]
                    MigrationTask["Migration Task (one-off)<br/>postgres:15-alpine<br/>SQL migrations + seeds"]
                end

                subgraph DataLayer["Data Layer"]
                    RDS[("RDS PostgreSQL 15<br/>db.t3.micro | 20 GB<br/>Encrypted | SSL required")]
                    Redis[("ElastiCache Redis 7.x<br/>cache.t3.micro<br/>Transit encryption")]
                end

                subgraph VPCEndpoints["VPC Endpoints (No Internet Required)"]
                    ECRA["ecr.api (Interface)"]
                    ECRD["ecr.dkr (Interface)"]
                    S3GW["s3 (Gateway)"]
                    SME["secretsmanager (Interface)"]
                    CWL["logs (Interface)"]
                end
            end
        end

        subgraph Supporting["Supporting Services (accessed via VPC Endpoints)"]
            ECR["ECR Repository"]
            SM["Secrets Manager"]
            CW["CloudWatch Logs + Alarms"]
            SNS["SNS Topic"]
        end
    end

    User -->|"HTTP :80<br/>(allowed IP/32)"| ALB
    ALB -->|HTTP :3000| AppService
    AppService -->|TCP :5432| RDS
    AppService -->|TCP :6379| Redis
    MigrationTask -->|TCP :5432| RDS

    AppService -.->|"HTTPS :443<br/>(VPC Endpoint)"| ECRA
    AppService -.->|"HTTPS :443<br/>(VPC Endpoint)"| SME
    AppService -.->|"HTTPS :443<br/>(VPC Endpoint)"| CWL
    ECSCluster -.->|"S3 layers<br/>(Gateway Endpoint)"| S3GW
```

## Security Group Matrix

```mermaid
graph LR
    YourIP["148.201.180.170/32"] -->|"TCP 80"| ALBSG["ALB SG"]
    ALBSG -->|"TCP 3000"| ECSSG["ECS Task SG"]
    ECSSG -->|"TCP 5432"| RDSSG["RDS SG"]
    ECSSG -->|"TCP 6379"| ECSG["ElastiCache SG"]
    ECSSG -->|"TCP 443"| VPCESG["VPC Endpoints SG"]
    ECSSG -->|"TCP 443"| S3PL["S3 Prefix List"]
    VPC_CIDR["VPC 10.0.0.0/16"] -->|"TCP 443"| VPCESG

    style ALBSG fill:#8C4FFF,stroke:#232F3E,color:white
    style ECSSG fill:#ED7100,stroke:#232F3E,color:white
    style RDSSG fill:#3B48CC,stroke:#232F3E,color:white
    style ECSG fill:#3B48CC,stroke:#232F3E,color:white
    style VPCESG fill:#3B8624,stroke:#232F3E,color:white
    style S3PL fill:#3B8624,stroke:#232F3E,color:white
```

## Network Flow (No Internet)

1. User → ALB (HTTP :80, restricted to allowed IP)
2. ALB → ECS Tasks (HTTP :3000, private subnet)
3. ECS Tasks → RDS (TCP :5432, private subnet, SSL required)
4. ECS Tasks → ElastiCache (TCP :6379, private subnet, TLS)
5. ECS Tasks → VPC Endpoints (HTTPS :443, private subnet, AWS internal network)
6. VPC Endpoints → ECR/S3/Secrets Manager/CloudWatch (AWS backbone, never internet)

## Tags (SCP Compliance)

All resources tagged with:
- `Team = "team-7"`
- `Name = "daniel.guzman@iteso.mx"`
- `Owner = "daniel.guzman@iteso.mx"`

Applied via Terraform `default_tags` + explicit tags on every resource.

## Auto-Scaling

| Parameter | Value |
|-----------|-------|
| Min tasks | 1 |
| Max tasks | 3 |
| Metric | ECSServiceAverageCPUUtilization |
| Threshold | 70% |
| Scale-out cooldown | 60 seconds |
| Scale-in cooldown | 300 seconds |

The ALB automatically distributes traffic across all running tasks. When CPU exceeds 70% average, ECS launches additional tasks (up to 3). When load decreases, it scales back down after 5 minutes of cooldown.

During load testing (3,600+ requests in 3 minutes), the service did not scale because Redis Cache-Aside absorbs 95%+ of read traffic without significant CPU impact. Scaling would activate under write-heavy workloads or Redis failures.

## Terraform Outputs

| Output | Value |
|--------|-------|
| ALB DNS | `reservflow-dev-alb-856383033.us-east-1.elb.amazonaws.com` |
| ECR URL | `311141527383.dkr.ecr.us-east-1.amazonaws.com/reservflow-dev` |
| RDS Endpoint | `reservflow-dev.csvwmqq42i9w.us-east-1.rds.amazonaws.com:5432` |
