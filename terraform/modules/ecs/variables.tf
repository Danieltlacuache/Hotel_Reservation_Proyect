# =============================================================================
# Variables for ECS module
# =============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "reservflow"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MB for the ECS task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository for the application image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS task placement"
  type        = list(string)
}

variable "ecs_task_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group for service registration"
  type        = string
}

variable "database_url_secret_arn" {
  description = "ARN of the Secrets Manager secret for DATABASE_URL"
  type        = string
}

variable "redis_url_secret_arn" {
  description = "ARN of the Secrets Manager secret for REDIS_URL"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for ECS task logs"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}
