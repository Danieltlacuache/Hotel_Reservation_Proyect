# =============================================================================
# Observability Module — CloudWatch Log Group, Metric Alarms for ECS Fargate
# =============================================================================

# =============================================================================
# CloudWatch Log Group for ECS Tasks
# =============================================================================

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/reservflow-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
    Module      = "observability"
  }
}

# =============================================================================
# CloudWatch Alarm — ECS CPU Utilization
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "reservflow-${var.environment}-cpu-utilization"
  alarm_description   = "Alarm when ECS service CPU utilization exceeds ${var.cpu_threshold}%"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
    Module      = "observability"
  }
}

# =============================================================================
# CloudWatch Alarm — ECS Memory Utilization
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "reservflow-${var.environment}-memory-utilization"
  alarm_description   = "Alarm when ECS service memory utilization exceeds ${var.memory_threshold}%"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.memory_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
    Module      = "observability"
  }
}

# =============================================================================
# CloudWatch Alarm — ALB Unhealthy Host Count
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "reservflow-${var.environment}-unhealthy-hosts"
  alarm_description   = "Alarm when ALB target group has unhealthy hosts"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Team        = "team-7"
    Name        = "daniel.guzman@iteso.mx"
    Owner       = "daniel.guzman@iteso.mx"
    Environment = var.environment
    Module      = "observability"
  }
}
