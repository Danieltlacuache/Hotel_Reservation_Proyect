# =============================================================================
# ReservFlow — Root Terraform Variables
# =============================================================================
# Override per environment using tfvars files:
#   terraform apply -var-file=environments/dev.tfvars
# =============================================================================

variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "team_tag" {
  description = "Team tag required by AWS organization SCP"
  type        = string
  default     = "team-7"
}

variable "name_tag" {
  description = "Name tag (ITESO email) required by AWS organization SCP"
  type        = string
  default     = "daniel.guzman@iteso.mx"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for subnet placement"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "container_image_tag" {
  description = "Docker image tag for the ECS task container (e.g. commit SHA or 'latest')"
  type        = string
  default     = "latest"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on ALB and CloudFront (empty string disables HTTPS)"
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain name (empty string disables)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB (your public IP/32). Update with your current public IP before applying."
  type        = list(string)
}

variable "sns_email" {
  description = "Email address for SNS alarm notifications (empty string disables subscription)"
  type        = string
  default     = ""
}
