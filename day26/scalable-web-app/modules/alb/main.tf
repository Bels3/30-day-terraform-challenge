locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Owner       = var.owner
    Day         = "26"
    Purpose     = "ApplicationLoadBalancer"
  }

  health_check = {
    dev = {
      interval            = 15
      timeout             = 5
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
    staging = {
      interval            = 20
      timeout             = 5
      healthy_threshold   = 3
      unhealthy_threshold = 2
    }
    prod = {
      interval            = 30
      timeout             = 5
      healthy_threshold   = 3
      unhealthy_threshold = 3
    }
  }[var.environment]
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound to instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web" {
  name               = substr("${local.name_prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  enable_http2               = true
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = substr("${local.name_prefix}-tg", 0, 32)
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.server_port
    protocol            = "HTTP"
    interval            = local.health_check.interval
    timeout             = local.health_check.timeout
    healthy_threshold   = local.health_check.healthy_threshold
    unhealthy_threshold = local.health_check.unhealthy_threshold
    matcher             = "200"
  }

  stickiness {
    enabled         = var.environment == "prod" ? true : false
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  deregistration_delay = var.environment == "prod" ? 300 : 30

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ================================================
# HTTP LISTENER - Port 80
# ================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.ssl_certificate_arn != null ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.ssl_certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    
    target_group_arn = var.ssl_certificate_arn == null ? aws_lb_target_group.web.arn : null
  }

  # Replace old listener instead of creating duplicate
  lifecycle {
    create_before_destroy = true
  }
}

# ================================================
# HTTPS LISTENER - Port 443 (Optional)
# ================================================
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ================================================
# MOVED BLOCK - Clean Migration from old listener
# ================================================
moved {
  from = aws_lb_listener.http_forward
  to   = aws_lb_listener.http
}

# CloudWatch Alarms (keep existing)
resource "aws_cloudwatch_metric_alarm" "high_request_count" {
  alarm_name          = "${local.name_prefix}-high-requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.environment == "prod" ? 2 : 1
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 1000 : 500

  dimensions = {
    TargetGroup  = aws_lb_target_group.web.arn_suffix
    LoadBalancer = aws_lb.web.arn_suffix
  }

  alarm_description = "High request count per target in ${var.environment} - consider scaling"
  alarm_actions     = []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 5 : 0

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
  }

  alarm_description = "ALB 5XX errors detected in ${var.environment}"
  alarm_actions     = []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  alarm_name          = "${local.name_prefix}-target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 5 : 0

  dimensions = {
    TargetGroup = aws_lb_target_group.web.arn_suffix
  }

  alarm_description = "Target 5XX errors detected in ${var.environment}"
  alarm_actions     = []

  tags = local.common_tags
}
