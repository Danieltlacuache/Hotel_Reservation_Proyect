# =============================================================================
# Variables for ALB module
# =============================================================================

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB placement"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (empty string disables HTTPS)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}
