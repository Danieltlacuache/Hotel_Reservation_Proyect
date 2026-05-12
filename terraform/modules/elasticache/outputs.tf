output "primary_endpoint" {
  description = "Primary endpoint address of the Redis replication group"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "port" {
  description = "Port number for the Redis cluster"
  value       = 6379
}
