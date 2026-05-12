output "database_url_secret_arn" {
  description = "ARN of the DATABASE_URL secret"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "redis_url_secret_arn" {
  description = "ARN of the REDIS_URL secret"
  value       = aws_secretsmanager_secret.redis_url.arn
}

output "rds_password_secret_arn" {
  description = "ARN of the RDS password secret"
  value       = aws_secretsmanager_secret.rds_password.arn
}
