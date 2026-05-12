# =============================================================================
# ReservFlow — Root Terraform Configuration
# =============================================================================
# ECS Fargate infrastructure for the ReservFlow hotel reservation system.
# Usage:
#   terraform init
#   terraform plan -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Provider
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Team  = "team-7"
      Name  = "daniel.guzman@iteso.mx"
      Owner = "daniel.guzman@iteso.mx"
    }
  }
}

# -----------------------------------------------------------------------------
# Module: VPC — Network isolation with public/private subnets
# -----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = var.vpc_cidr
  environment         = var.environment
  availability_zones  = var.availability_zones
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

# -----------------------------------------------------------------------------
# Module: ECR — Container image registry
# -----------------------------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  repository_name = "reservflow"
  environment     = var.environment
}

# -----------------------------------------------------------------------------
# Module: RDS — PostgreSQL database
# -----------------------------------------------------------------------------

module "rds" {
  source = "./modules/rds"

  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  db_name            = "reservflow"
  db_username        = "reservflow_admin"
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.vpc.rds_sg_id
  environment        = var.environment
}

# -----------------------------------------------------------------------------
# Module: ElastiCache — Redis caching layer
# -----------------------------------------------------------------------------

module "elasticache" {
  source = "./modules/elasticache"

  private_subnet_ids = module.vpc.private_subnet_ids
  elasticache_sg_id  = module.vpc.elasticache_sg_id
  environment        = var.environment
}

# -----------------------------------------------------------------------------
# Module: Secrets — AWS Secrets Manager for sensitive values
# -----------------------------------------------------------------------------

module "secrets" {
  source = "./modules/secrets"

  database_url = "postgresql://reservflow_admin:${var.db_password}@${module.rds.address}:${module.rds.port}/reservflow"
  redis_url    = "rediss://${module.elasticache.primary_endpoint}:${module.elasticache.port}"
  rds_password = var.db_password
  environment  = var.environment
}

# -----------------------------------------------------------------------------
# Module: ALB — Application Load Balancer
# -----------------------------------------------------------------------------

module "alb" {
  source = "./modules/alb"

  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.vpc.alb_sg_id
  vpc_id            = module.vpc.vpc_id
  certificate_arn   = var.certificate_arn
  environment       = var.environment
}

# -----------------------------------------------------------------------------
# Module: Observability — CloudWatch logs, metrics, and alarms
# -----------------------------------------------------------------------------

module "observability" {
  source = "./modules/observability"

  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  environment             = var.environment
}

# -----------------------------------------------------------------------------
# Module: ECS — Fargate cluster, service, and task definitions
# -----------------------------------------------------------------------------

module "ecs" {
  source = "./modules/ecs"

  ecr_repository_url      = module.ecr.repository_url
  image_tag               = var.container_image_tag
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_task_sg_id          = module.vpc.ecs_task_sg_id
  target_group_arn        = module.alb.target_group_arn
  database_url_secret_arn = module.secrets.database_url_secret_arn
  redis_url_secret_arn    = module.secrets.redis_url_secret_arn
  log_group_name          = module.observability.log_group_name
  environment             = var.environment
}


