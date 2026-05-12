resource "aws_ecr_repository" "this" {
  name                 = "${var.repository_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain only last ${var.image_retention_count} untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
