resource "aws_elasticache_subnet_group" "this" {
  name       = "reservflow-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "reservflow-${var.environment}"
  description          = "ReservFlow Redis replication group - ${var.environment}"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes

  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.elasticache_sg_id]

  transit_encryption_enabled = true

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}
