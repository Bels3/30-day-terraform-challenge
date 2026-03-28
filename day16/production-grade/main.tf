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

# LOCALS

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.team_name
  }
}

# DATA SOURCES 

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SECURITY GROUPS 

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

# LAUNCH TEMPLATE

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
    python3 -c "
    html = '''<!DOCTYPE html>
    <html lang=\"en\">
    <head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Day 16 - Production-Grade Infrastructure</title>
    <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{background:#0d1117;font-family:Segoe UI,system-ui,sans-serif;color:#e6edf3;min-height:100vh;}
    .hero{background:#0d1117;border-bottom:1px solid #21262d;padding:48px 40px 40px;}
    .badge{display:inline-flex;align-items:center;gap:6px;background:rgba(255,153,0,0.1);border:1px solid rgba(255,153,0,0.3);border-radius:20px;padding:4px 14px;font-size:12px;font-weight:600;color:#ff9900;letter-spacing:0.5px;margin-bottom:20px;}
    h1{font-size:42px;font-weight:700;line-height:1.15;margin-bottom:10px;letter-spacing:-1px;}
    h1 span{color:#ff9900;}
    .subtitle{font-size:16px;color:#8b949e;margin-bottom:32px;line-height:1.6;}
    .meta-row{display:flex;gap:24px;flex-wrap:wrap;}
    .meta-item{display:flex;align-items:center;gap:8px;font-size:13px;color:#8b949e;}
    .meta-dot{width:8px;height:8px;border-radius:50%;}
    .dot-green{background:#3fb950;}.dot-orange{background:#ff9900;}.dot-blue{background:#388bfd;}
    .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;padding:32px 40px;}
    .card{background:#161b22;border:1px solid #21262d;border-radius:12px;padding:20px;}
    .card-label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:0.8px;color:#8b949e;margin-bottom:8px;}
    .card-value{font-size:22px;font-weight:700;color:#e6edf3;font-family:Courier New,monospace;}
    .card-sub{font-size:12px;color:#8b949e;margin-top:4px;}
    .card-accent{border-left:3px solid #ff9900;}
    .section{padding:0 40px 32px;}
    .section-title{font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:0.8px;color:#8b949e;margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid #21262d;}
    .checklist{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:10px;}
    .check-item{display:flex;align-items:center;gap:10px;background:#161b22;border:1px solid #21262d;border-radius:8px;padding:12px 14px;}
    .check-icon{width:20px;height:20px;border-radius:50;background:rgba(63,185,80,0.15);border:1px solid rgba(63,185,80,0.4);display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .check-text{font-size:13px;color:#c9d1d9;font-weight:500;}
    .code-block{background:#161b22;border:1px solid #21262d;border-radius:8px;padding:16px 20px;font-family:Courier New,monospace;font-size:13px;color:#e6edf3;line-height:1.7;margin-bottom:24px;}
    .code-key{color:#ff9900;}.code-str{color:#79c0ff;}
    .footer{padding:24px 40px;border-top:1px solid #21262d;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;}
    .footer-left{font-size:13px;color:#8b949e;}
    .footer-right{font-size:12px;color:#30363d;font-family:Courier New,monospace;}
    </style>
    </head>
    <body>
    <div class=\"hero\">
    <div class=\"badge\">DAY 16 . 30-DAY TERRAFORM CHALLENGE</div>
    <h1>Production-Grade<br><span>Infrastructure</span></h1>
    <p class=\"subtitle\">Deployed with Terraform. Hardened with lifecycle rules, CloudWatch alarms, input validation, and consistent tagging.</p>
    <div class=\"meta-row\">
    <div class=\"meta-item\"><span class=\"meta-dot dot-green\"></span>ALB healthy</div>
    <div class=\"meta-item\"><span class=\"meta-dot dot-orange\"></span>eu-west-1 . Ireland</div>
    <div class=\"meta-item\"><span class=\"meta-dot dot-blue\"></span>IMDSv2 enforced</div>
    <div class=\"meta-item\"><span class=\"meta-dot dot-green\"></span>S3 state . encrypted</div>
    </div></div>
    <div class=\"cards\">
    <div class=\"card card-accent\"><div class=\"card-label\">Cluster</div><div class=\"card-value\">prod-grade</div><div class=\"card-sub\">Environment: dev</div></div>
    <div class=\"card\"><div class=\"card-label\">Instance type</div><div class=\"card-value\">t2.micro</div><div class=\"card-sub\">t2 / t3 validated</div></div>
    <div class=\"card\"><div class=\"card-label\">ASG capacity</div><div class=\"card-value\">2 . 4</div><div class=\"card-sub\">min . max</div></div>
    <div class=\"card\"><div class=\"card-label\">Health check</div><div class=\"card-value\">ELB</div><div class=\"card-sub\">15s interval</div></div>
    <div class=\"card\"><div class=\"card-label\">CPU alarm</div><div class=\"card-value\">80</div><div class=\"card-sub\">SNS . 4 min eval</div></div>
    <div class=\"card\"><div class=\"card-label\">State lock</div><div class=\"card-value\">S3</div><div class=\"card-sub\">Native . encrypted</div></div>
    </div>
    <div class=\"section\">
    <div class=\"section-title\">Production checklist</div>
    <div class=\"checklist\">
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Code structure</span></div>
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Reliability</span></div>
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Security</span></div>
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Observability</span></div>
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Maintainability</span></div>
    <div class=\"check-item\"><div class=\"check-icon\">+</div><span class=\"check-text\">Input validation</span></div>
    </div></div>
    <div class=\"section\">
    <div class=\"section-title\">Resource tags</div>
    <div class=\"code-block\">
    <div><span class=\"code-key\">Environment</span> = <span class=\"code-str\">dev</span></div>
    <div><span class=\"code-key\">ManagedBy</span> = <span class=\"code-str\">terraform</span></div>
    <div><span class=\"code-key\">Project</span> = <span class=\"code-str\">30-day-terraform-challenge</span></div>
    <div><span class=\"code-key\">Owner</span> = <span class=\"code-str\">beldine</span></div>
    </div></div>
    <div class=\"footer\">
    <div class=\"footer-left\">Beldine Oluoch . No 2 on leaderboard . 262 participants</div>
    <div class=\"footer-right\">terraform apply . 15 resources . 0 errors</div>
    </div>
    </body></html>'''
    with open('/var/www/html/index.html', 'w') as f:
        f.write(html)
    "
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-launch-template"
  })
}

# AUTO SCALING GROUP 

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

# ALB 

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

# CLOUDWATCH ALARMS

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

# LOG GROUP

resource "aws_cloudwatch_log_group" "web" {
  name              = "/terraform/${var.cluster_name}"
  retention_in_days = 30

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-log-group"
  })
}
