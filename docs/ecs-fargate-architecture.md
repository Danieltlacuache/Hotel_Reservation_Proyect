# ReservFlow — ECS Fargate Infrastructure Architecture

## System Architecture

```mermaid
graph TB
    subgraph Internet
        User[("👤 User Browser")]
    end

    subgraph AWS["AWS Cloud — us-east-1 (Account: 311141527383)"]
        
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
                    MigrationTask["Migration Task (one-off)<br/>PostgreSQL Client<br/>Runs 4 SQL migrations"]
                end

                subgraph DataLayer["Data Layer"]
                    RDS[("RDS PostgreSQL 15<br/>db.t3.micro | 20 GB<br/>Encrypted | Private")]
                    Redis[("ElastiCache Redis 7.x<br/>cache.t3.micro<br/>Encryption in transit")]
                end
            end
        end

        subgraph Supporting["Supporting Services"]
            ECR["ECR Repository<br/>reservflow<br/>Image scanning enabled"]
            SM["Secrets Manager<br/>DATABASE_URL<br/>REDIS_URL<br/>RDS Password"]
            CW["CloudWatch<br/>Log Group (14d retention)<br/>CPU/Memory/Health Alarms"]
            SNS["SNS Topic<br/>Alarm Notifications"]
        end
    end

    %% Traffic Flow
    User -->|HTTPS| CDN
    CDN -->|HTTP :80| ALB
    ALB -->|HTTP :3000| AppService
    AppService -->|TCP :5432| RDS
    AppService -->|TCP :6379| Redis
    MigrationTask -->|TCP :5432| RDS

    %% Supporting connections
    AppService -.->|Pull image| ECR
    AppService -.->|Resolve secrets| SM
    MigrationTask -.->|Resolve secrets| SM
    AppService -.->|Logs| CW
    CW -.->|Alarm| SNS
    PrivateSubnets -.->|Outbound| NAT
    NAT -.->|Internet| IGW

    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,color:#232F3E
    classDef compute fill:#ED7100,stroke:#232F3E,color:white
    classDef database fill:#3B48CC,stroke:#232F3E,color:white
    classDef network fill:#8C4FFF,stroke:#232F3E,color:white
    classDef security fill:#DD344C,stroke:#232F3E,color:white

    class CDN,ALB,NAT,IGW network
    class AppService,MigrationTask compute
    class RDS,Redis database
    class SM security
    class ECR,CW,SNS aws
```

## Security Group Rules

```mermaid
graph LR
    subgraph SecurityGroups["Security Group Matrix"]
        Internet2["0.0.0.0/0"] -->|"TCP 80, 443"| ALBSG["ALB SG"]
        ALBSG -->|"TCP 3000"| ECSSG["ECS Task SG"]
        ECSSG -->|"TCP 5432"| RDSSG["RDS SG"]
        ECSSG -->|"TCP 6379"| ECSG["ElastiCache SG"]
    end

    style ALBSG fill:#8C4FFF,stroke:#232F3E,color:white
    style ECSSG fill:#ED7100,stroke:#232F3E,color:white
    style RDSSG fill:#3B48CC,stroke:#232F3E,color:white
    style ECSG fill:#3B48CC,stroke:#232F3E,color:white
```

## Terraform Module Dependencies

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

    %% Dependencies (outputs → inputs)
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

## Tags (SCP Compliance)

All resources are tagged with:
- `Team = "team-7"`
- `Name = "daniel.guzman@iteso.mx"`

Applied via Terraform `default_tags` provider block + explicit tags where required at creation time.
