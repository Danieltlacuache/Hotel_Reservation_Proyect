output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ecs_task_sg_id" {
  description = "ID of the ECS task security group"
  value       = aws_security_group.ecs_task.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "elasticache_sg_id" {
  description = "ID of the ElastiCache security group"
  value       = aws_security_group.elasticache.id
}
