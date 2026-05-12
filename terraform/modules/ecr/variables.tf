variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "reservflow"
}

variable "image_retention_count" {
  description = "Number of untagged images to retain"
  type        = number
  default     = 10
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
