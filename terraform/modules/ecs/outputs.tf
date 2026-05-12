# =============================================================================
# Outputs for ECS module
# =============================================================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.execution.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster (for CloudWatch dimensions)"
  value       = aws_ecs_cluster.this.name
}

output "migration_task_definition_arn" {
  description = "ARN of the migration task definition"
  value       = aws_ecs_task_definition.migration.arn
}
