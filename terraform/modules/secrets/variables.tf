variable "database_url" {
  description = "PostgreSQL connection string"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis connection URL"
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
