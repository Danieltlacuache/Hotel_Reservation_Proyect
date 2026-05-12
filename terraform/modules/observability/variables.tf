# =============================================================================
# Variables for Observability module
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to monitor"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group for CloudWatch metrics"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization alarm threshold (percentage)"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization alarm threshold (percentage)"
  type        = number
  default     = 80
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (empty string disables notifications)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}
