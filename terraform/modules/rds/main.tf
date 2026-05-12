resource "aws_db_subnet_group" "this" {
  name       = "reservflow-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  identifier     = "reservflow-${var.environment}"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  publicly_accessible     = false
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}
