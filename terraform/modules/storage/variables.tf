# =============================================================================
# Variables for Storage module
# =============================================================================

variable "environment" {
  description = "Environment name used as prefix for resource names (e.g. dev, prod)"
  type        = string
}

variable "team_tag" {
  description = "Team tag required by AWS organization SCP"
  type        = string
}

variable "name_tag" {
  description = "Name tag (email) required by AWS organization SCP"
  type        = string
}

variable "photos_bucket_name" {
  description = "Name of the pre-created S3 photos bucket"
  type        = string
}

variable "frontend_bucket_name" {
  description = "Name of the pre-created S3 frontend bucket"
  type        = string
}
