###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Internet Gateway (needed for ALB in public subnets)
###############################################################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Public Subnets (one per AZ - for ALB only, restricted to allowed IPs)
###############################################################################

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Private Subnets (one per AZ - for ECS, RDS, ElastiCache)
###############################################################################

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Public Route Table (0.0.0.0/0 → Internet Gateway) - ALB only
###############################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Private Route Table (no internet route - uses VPC Endpoints)
###############################################################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

###############################################################################
# Security Group: VPC Endpoints (HTTPS from private subnets)
###############################################################################

resource "aws_security_group" "vpc_endpoints" {
  name        = "reservflow-${var.environment}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# VPC Endpoints — Replace NAT Gateway for private subnet access to AWS services
###############################################################################

# ECR API (for ECS to authenticate and get image manifests)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

# ECR Docker (for ECS to pull container layers)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

# S3 Gateway Endpoint (ECR stores layers in S3)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

# Secrets Manager (for ECS to resolve secrets at task launch)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

# CloudWatch Logs (for ECS awslogs driver)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Security Group: ALB (inbound 80, 443 from ALLOWED IPs ONLY - no 0.0.0.0/0)
###############################################################################

resource "aws_security_group" "alb" {
  name        = "reservflow-${var.environment}-alb-sg"
  description = "Security group for ALB - restricted to allowed IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS from allowed IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Security Group: ECS Task (inbound 3000 from ALB SG)
###############################################################################

resource "aws_security_group" "ecs_task" {
  name        = "reservflow-${var.environment}-ecs-task-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Application port from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description     = "HTTPS to VPC Endpoints and S3 Gateway"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    description = "PostgreSQL to RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Redis to ElastiCache"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Security Group: RDS (inbound 5432 from ECS Task SG)
###############################################################################

resource "aws_security_group" "rds" {
  name        = "reservflow-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
  }

  egress {
    description = "No outbound needed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}

###############################################################################
# Security Group: ElastiCache (inbound 6379 from ECS Task SG)
###############################################################################

resource "aws_security_group" "elasticache" {
  name        = "reservflow-${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
  }

  egress {
    description = "No outbound needed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Team  = "team-7"
    Name  = "daniel.guzman@iteso.mx"
    Owner = "daniel.guzman@iteso.mx"
  }
}
