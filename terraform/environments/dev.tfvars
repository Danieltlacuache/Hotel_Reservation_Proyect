# =============================================================================
# ReservFlow — Dev Environment Variables
# =============================================================================

environment        = "dev"
aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# ECS Task sizing
# task_cpu    = 256   (module default)
# task_memory = 512   (module default)
# desired_count = 1   (module default)

# RDS
# instance_class    = "db.t3.micro"  (module default)
# allocated_storage = 20             (module default)

# Container
container_image_tag = "latest"

# HTTPS (disabled for dev)
certificate_arn = ""
custom_domain   = ""

# Access restriction — Replace with your current public IP/32
# Find your public IP: curl ifconfig.me
allowed_cidr_blocks = ["148.201.180.170/32"]

# Notifications
sns_email = ""
