variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the replication group"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cache subnet group"
  type        = list(string)
}

variable "elasticache_sg_id" {
  description = "Security group ID for the ElastiCache cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
