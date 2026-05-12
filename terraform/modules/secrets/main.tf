# DATABASE_URL secret
resource "aws_secretsmanager_secret" "database_url" {
  name = "reservflow/${var.environment}/DATABASE_URL"

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = var.database_url
}

# REDIS_URL secret
resource "aws_secretsmanager_secret" "redis_url" {
  name = "reservflow/${var.environment}/REDIS_URL"

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id     = aws_secretsmanager_secret.redis_url.id
  secret_string = var.redis_url
}

# RDS master password secret
resource "aws_secretsmanager_secret" "rds_password" {
  name = "reservflow/${var.environment}/rds-password"

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = var.rds_password
}
