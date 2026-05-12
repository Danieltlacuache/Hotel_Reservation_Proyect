# =============================================================================
# ReservFlow — Production Environment Variables
# =============================================================================

environment        = "prod"
aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# ECS Task sizing (production)
# task_cpu      = 512    (set in module wiring, Task 12)
# task_memory   = 1024   (set in module wiring, Task 12)
# desired_count = 2      (set in module wiring, Task 12)

# RDS (production)
# instance_class    = "db.t3.small"  (set in module wiring, Task 12)
# allocated_storage = 50             (set in module wiring, Task 12)

# Container
container_image_tag = "latest"

# HTTPS (configure when certificate is available)
certificate_arn = ""
custom_domain   = ""

# Notifications
sns_email = ""
