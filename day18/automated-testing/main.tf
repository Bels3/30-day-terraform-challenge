terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.team_name
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.alb_port
  to_port           = var.alb_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for the EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-instance-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "instance_http" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "instance_all" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Hello from ${var.cluster_name} - Day 18 Automated Testing</h1>" > /var/www/html/index.html
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-launch-template"
  })
}

resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.cluster_name}-"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb" "web" {
  name_prefix        = substr(var.cluster_name, 0, 6)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name_prefix = substr(var.cluster_name, 0, 6)
  port        = var.server_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-listener"
  })
}

resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alerts"
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when CPU exceeds 80 percent for 4 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-high-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.cluster_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Triggers when any target group instance becomes unhealthy"

  dimensions = {
    TargetGroup  = aws_lb_target_group.web.arn_suffix
    LoadBalancer = aws_lb.web.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-unhealthy-hosts-alarm"
  })
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/terraform/${var.cluster_name}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-log-group"
  })
}
