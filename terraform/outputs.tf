# =============================================================================
# ReservFlow — Root Terraform Outputs
# =============================================================================
# Key endpoints and resource identifiers exposed for CI/CD pipelines and
# operational use.
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for pushing container images"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS PostgreSQL instance"
  value       = module.rds.endpoint
}

output "migration_task_definition_arn" {
  description = "ARN of the ECS task definition for running database migrations"
  value       = module.ecs.migration_task_definition_arn
}
