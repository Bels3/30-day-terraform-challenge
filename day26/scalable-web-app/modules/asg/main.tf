locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Owner       = var.owner
    Day         = "26"
    Purpose     = "AutoScalingGroup"
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period

  # Real-world production settings
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  termination_policies = [
    "Default",
  ]

  suspended_processes = var.environment == "dev" ? ["AZRebalance"] : []

  default_instance_warmup = var.environment == "prod" ? 300 : 60

  max_instance_lifetime = var.environment == "prod" ? 2592000 : 0 # 30 days for prod

  protect_from_scale_in = var.enable_scale_in_protection

  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${local.name_prefix}-web-instance"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_capacity, # Allow external scaling
    ]
  }
}

# Scale-out policy based on CPU
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${local.name_prefix}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_out_cooldown
  autoscaling_group_name = aws_autoscaling_group.web.name

}

# Scale-in policy based on CPU
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.name_prefix}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_in_cooldown
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# Target tracking scaling policy (more sophisticated than step scaling)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = 50.0
    disable_scale_in = false
  }

}

# CloudWatch Alarm - CPU High (Step Scaling)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.environment == "prod" ? 3 : 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale out when average CPU >= ${var.cpu_scale_out_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]

  tags = local.common_tags
}

# CloudWatch Alarm - CPU Low (Step Scaling)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.environment == "prod" ? 6 : 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale in when average CPU <= ${var.cpu_scale_in_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]

  tags = local.common_tags
}

# CloudWatch Alarm - High Request Count (wired to scale-out)
resource "aws_cloudwatch_metric_alarm" "high_request_scale" {
  count = var.enable_request_based_scaling ? 1 : 0
  alarm_name          = "${local.name_prefix}-high-request-scale"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1000

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale out due to high request count per target"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]

  tags = local.common_tags
}

# SNS Notification for scaling events
resource "aws_autoscaling_notification" "scaling_notifications" {
  count = var.sns_topic_arn != null ? 1 : 0

  group_names = [aws_autoscaling_group.web.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]

  topic_arn = var.sns_topic_arn
}

# BONUS: CloudWatch Dashboard

resource "aws_cloudwatch_dashboard" "web_asg" {
  dashboard_name = "${local.name_prefix}-web-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ASG Instance Count Widget
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ASG Instance Count - ${var.environment}"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "In Service", color = "#2ecc71" }],
            [".", "GroupDesiredCapacity", ".", ".", { label = "Desired", color = "#3498db" }],
            [".", "GroupMinSize", ".", ".", { label = "Min Size", color = "#95a5a6", stat = "Minimum" }],
            [".", "GroupMaxSize", ".", ".", { label = "Max Size", color = "#e74c3c", stat = "Maximum" }]
          ]
          yAxis = {
            left = {
              label = "Instance Count"
              min   = 0
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Scale-out threshold (CPU)"
                value = var.cpu_scale_out_threshold
                color = "#e67e22"
                fill  = "above"
              }
            ]
          }
        }
      },

      # CPU Utilization Widget
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CPU Utilization - ${var.environment}"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "Average CPU %", color = "#9b59b6" }]
          ]
          yAxis = {
            left = {
              label = "CPU %"
              min   = 0
              max   = 100
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Scale-out threshold (${var.cpu_scale_out_threshold}%)"
                value = var.cpu_scale_out_threshold
                color = "#e74c3c"
              },
              {
                label = "Scale-in threshold (${var.cpu_scale_in_threshold}%)"
                value = var.cpu_scale_in_threshold
                color = "#27ae60"
              },
              {
                label = "Target tracking (50%)"
                value = 50
                color = "#f39c12"
                fill  = "above"
              }
            ]
          }
        }
      },

      # ALB Request Count Widget
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "ALB Request Count - ${var.environment}"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", split("/", var.target_group_arns[0])[2], { label = "Requests/min", color = "#1abc9c" }]
          ]
        }
      },

      # Network Traffic Widget
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "Network Traffic - ${var.environment}"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "Network In (Bytes)", color = "#3498db" }],
            [".", "NetworkOut", ".", ".", { label = "Network Out (Bytes)", color = "#e67e22" }]
          ]
        }
      },

      # Health Check Status Widget
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "Target Group Health - ${var.environment}"
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", split("/", var.target_group_arns[0])[2], { label = "Healthy Hosts", color = "#2ecc71" }],
            [".", "UnHealthyHostCount", ".", ".", { label = "Unhealthy Hosts", color = "#e74c3c" }]
          ]
        }
      },

      # Text widget with scaling info
      {
        type   = "text"
        x      = 0
        y      = 12
        width  = 24
        height = 3
        properties = {
          markdown = <<-MARKDOWN
          # 🚀 Auto Scaling Configuration - ${var.environment}
          
          | Min Size | Max Size | Desired | Scale-out CPU | Scale-in CPU | Target CPU | Cooldown |
          |----------|----------|---------|---------------|--------------|------------|----------|
          | **${var.min_size}** | **${var.max_size}** | **${var.desired_capacity}** | **${var.cpu_scale_out_threshold}%** | **${var.cpu_scale_in_threshold}%** | **50%** | **${var.scale_out_cooldown}s** |
          
          **Alarms configured:** CPU High, CPU Low, Request Count | **Health Check:** ELB | **Instance Refresh:** Rolling (90% healthy)
          MARKDOWN
        }
      }
    ]
  })
}

data "aws_region" "current" {}
