# ReservFlow — Project Context for Infrastructure Design

## Project Overview

ReservFlow is a hotel reservation system built as a monolithic Next.js application. The Docker image is available at `nino200431/reservflow:latest` on Docker Hub.

## Application Architecture

- **Framework:** Next.js 14 with TypeScript (standalone output)
- **Runtime:** Node.js 20
- **Port:** 3000
- **Database:** PostgreSQL (via `pg` library)
- **Cache:** Redis (via `ioredis`)
- **Validation:** Zod
- **Testing:** Vitest + fast-check (property-based testing)
- **Styling:** Tailwind CSS

## Docker Image Details

- Image: `nino200431/reservflow:latest`
- Base: Node.js 20 Alpine
- Entrypoint: `node server.js`
- Working directory: `/app`
- Exposed port: 3000
- User: `nextjs` (non-root)

## Required AWS Infrastructure

Since this is a monolithic app (not serverless), it needs:

| Service | Purpose |
|---------|---------|
| ECS Fargate | Run the Next.js container |
| Application Load Balancer | Route traffic to ECS tasks |
| RDS PostgreSQL | Database (db.t3.micro for dev) |
| ElastiCache Redis | Caching layer |
| ECR | Store container images for ECS |
| CloudFront | CDN in front of ALB |
| VPC | Private networking for RDS/Redis |
| Secrets Manager | DB credentials, Redis URL |
| CloudWatch | Logs, metrics, alarms |
| S3 | Static assets (if needed) |

## AWS Account Constraints (Teacher's Account)

Account: 311141527383
Region: us-east-1 ONLY
Team: team-7
Name tag: daniel.guzman@iteso.mx

### SCP Restrictions (CRITICAL)

1. ALL resources MUST have tags: `Team = team-7` and `Name = daniel.guzman@iteso.mx`
2. Region restricted to `us-east-1` only
3. S3 buckets CANNOT be made public (use CloudFront OAC)
4. S3 CreateBucket is blocked by SCP via Terraform — must create buckets via AWS Console
5. No open ports (SSH/RDP) to 0.0.0.0/0
6. EC2 instances: only t2, t3, t3a, t4g families
7. RDS instances: only db.t2, db.t3, db.t4g families
8. No IAM users with console access
9. Cannot attach AdministratorAccess/IAMFullAccess/PowerUserAccess to IAM users
10. Use `default_tags` in Terraform provider for automatic tag propagation
11. Access via SSO (AdministratorAccess role) — temporary credentials that expire every few hours

### Terraform Tagging Pattern

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Team = "team-7"
      Name = "daniel.guzman@iteso.mx"
    }
  }
}
```

Add explicit tags to each resource as well (some services require it at creation time).

### S3 Bucket Workaround

Terraform cannot create S3 buckets in this account (SCP blocks it). Workaround:
1. Create buckets manually via AWS Console (with tags in the creation wizard)
2. Import them into Terraform state: `terraform import module.storage.aws_s3_bucket.name bucket-name`
3. Use `prevent_destroy = true` and `ignore_changes = [tags, tags_all]` in the resource

### Credentials

- SSO Portal: https://joalgama.awsapps.com/start/#/
- Use AdministratorAccess role
- Credentials expire every 1-4 hours — refresh from SSO portal
- Docker Hub: nino200431

## CI/CD Requirements

- GitHub Actions pipelines
- Backend pipeline: Build → Test → Docker Push → Deploy Dev → Manual Gate → Deploy Prod
- Two environments: Dev (teacher's account us-east-1) and Prod (partner's account)
- Docker images pushed to Docker Hub AND ECR
- Manual approval gate for production (GitHub Environments)
- Unit tests with Vitest (visible in pipeline)

## Terraform Module Structure (Proposed)

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── environments/
│   ├── dev.tfvars
│   └── prod.tfvars
└── modules/
    ├── vpc/           # VPC, subnets, security groups
    ├── ecs/           # ECS cluster, service, task definition
    ├── rds/           # PostgreSQL instance
    ├── elasticache/   # Redis cluster
    ├── alb/           # Application Load Balancer
    ├── ecr/           # Container registry
    ├── cloudfront/    # CDN distribution
    ├── secrets/       # Secrets Manager
    └── observability/ # CloudWatch, alarms, SNS
```

## Key Differences from Previous Project (CondoManager)

| Aspect | CondoManager | ReservFlow |
|--------|-------------|------------|
| Compute | Lambda (serverless) | ECS Fargate (container) |
| Database | DynamoDB (NoSQL) | PostgreSQL (SQL) |
| Cache | External Redis (Upstash) | ElastiCache Redis (AWS) |
| Frontend | Separate S3 + CloudFront | Included in Next.js (SSR) |
| Networking | No VPC needed | VPC required (private subnets) |
| Scaling | Automatic (Lambda) | ECS auto-scaling policies |
| Cost model | Pay per request | Pay per running task |

## Deployment Flow

1. Push code → GitHub Actions triggers
2. Build Docker image → Push to ECR
3. Update ECS task definition with new image
4. ECS deploys new tasks (rolling update)
5. ALB routes traffic to healthy tasks
6. CloudFront serves via ALB origin

## Notes for Next Session

- Open the Hotel_Reservation_Proyect repo as workspace
- Tell Kiro: "Design Terraform infrastructure for ReservFlow (Next.js + PostgreSQL + Redis on ECS Fargate). Check docs/reservflow-project-context.md for full context."
- The infrastructure guide from the previous project (docs/infrastructure-guide.md) has useful patterns for SCP compliance
