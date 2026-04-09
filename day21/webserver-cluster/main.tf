terraform {
  required_version = ">= 1.0"

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

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security groups
resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for ASG instances Day 21"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.cluster_name}-instance-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
    Day         = "21"
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_http" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP from ALB only"
}

resource "aws_vpc_security_group_egress_rule" "instance_all" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB Day 21"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
    Day         = "21"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.alb_port
  to_port           = var.alb_port
  ip_protocol       = "tcp"
  description       = "Allow HTTP from internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

# Launch template
resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  # IMDSv2 enforced — closes SSRF credential theft vector
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
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Day 21 — Terraform 30-Day Challenge</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          background: #0d1117;
          color: #c9d1d9;
          font-family: 'Courier New', monospace;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .container {
          max-width: 720px;
          width: 100%;
          padding: 2rem;
        }
        .badge {
          display: inline-block;
          background: #ff9900;
          color: #0d1117;
          font-weight: 700;
          padding: 4px 14px;
          border-radius: 12px;
          font-size: 13px;
          margin-bottom: 1.5rem;
        }
        h1 {
          font-size: 1.6rem;
          color: #ff9900;
          margin-bottom: 0.4rem;
        }
        .subtitle {
          color: #8b949e;
          font-size: 0.9rem;
          margin-bottom: 2rem;
          border-bottom: 1px solid #30363d;
          padding-bottom: 1rem;
        }
        .golden-rule {
          background: #161b27;
          border-left: 3px solid #ff9900;
          padding: 1rem 1.2rem;
          margin-bottom: 2rem;
          border-radius: 0 4px 4px 0;
        }
        .golden-rule .label {
          font-size: 10px;
          color: #ff9900;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 6px;
        }
        .golden-rule blockquote {
          color: #e6edf3;
          font-style: italic;
          font-size: 0.95rem;
          line-height: 1.6;
        }
        .golden-rule cite {
          display: block;
          margin-top: 8px;
          font-size: 0.8rem;
          color: #8b949e;
          font-style: normal;
        }
        .grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 1rem;
          margin-bottom: 2rem;
        }
        .card {
          background: #161b27;
          border: 1px solid #30363d;
          border-radius: 4px;
          padding: 1rem;
        }
        .card-title {
          font-size: 10px;
          color: #ff9900;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 8px;
        }
        .card-value {
          font-size: 0.9rem;
          color: #e6edf3;
        }
        .safeguards {
          background: #161b27;
          border: 1px solid #30363d;
          border-radius: 4px;
          padding: 1rem;
          margin-bottom: 2rem;
        }
        .safeguards-title {
          font-size: 10px;
          color: #3fb950;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 10px;
        }
        .safeguard-item {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 6px;
          font-size: 0.85rem;
        }
        .check { color: #3fb950; }
        .insights {
          background: #161b27;
          border: 1px solid #30363d;
          border-radius: 4px;
          padding: 1rem;
        }
        .insights-title {
          font-size: 10px;
          color: #58a6ff;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 10px;
        }
        .insight {
          font-size: 0.82rem;
          color: #8b949e;
          margin-bottom: 6px;
          padding-left: 12px;
          border-left: 2px solid #30363d;
          line-height: 1.5;
        }
        .insight strong { color: #c9d1d9; }
        .footer {
          margin-top: 2rem;
          font-size: 0.75rem;
          color: #484f58;
          text-align: center;
          border-top: 1px solid #30363d;
          padding-top: 1rem;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="badge">Day 21 of 30</div>
        <h1>Infrastructure Deployment Workflow</h1>
        <p class="subtitle">30-Day Terraform Challenge &nbsp;·&nbsp; Beldine Oluoch &nbsp;·&nbsp; eu-west-1</p>

        <div class="golden-rule">
          <div class="label">Brikman's Golden Rule of Terraform</div>
          <blockquote>
            "The master branch of a live repository should always represent the
            desired state of your infrastructure."
          </blockquote>
          <cite>— Yevgeniy Brikman, Terraform: Up &amp; Running, Chapter 10</cite>
        </div>

        <div class="grid">
          <div class="card">
            <div class="card-title">Cluster</div>
            <div class="card-value">${var.cluster_name}</div>
          </div>
          <div class="card">
            <div class="card-title">Environment</div>
            <div class="card-value">${var.environment}</div>
          </div>
          <div class="card">
            <div class="card-title">Instance Type</div>
            <div class="card-value">${var.instance_type}</div>
          </div>
          <div class="card">
            <div class="card-title">Region</div>
            <div class="card-value">${var.region}</div>
          </div>
        </div>

        <div class="safeguards">
          <div class="safeguards-title">Active Safeguards</div>
          <div class="safeguard-item"><span class="check">✓</span> IMDSv2 enforced — SSRF closed</div>
          <div class="safeguard-item"><span class="check">✓</span> Saved plan applied — day21.tfplan</div>
          <div class="safeguard-item"><span class="check">✓</span> State versioning — S3 + use_lockfile</div>
          <div class="safeguard-item"><span class="check">✓</span> Sentinel policy — instance type allowlist</div>
          <div class="safeguard-item"><span class="check">✓</span> Blast radius documented in PR</div>
          <div class="safeguard-item"><span class="check">✓</span> ALB request count alarm active</div>
        </div>

        <div class="insights">
          <div class="insights-title">Key Insights — Chapter 10</div>
          <div class="insight"><strong>Work incrementally.</strong> Never migrate everything at once. Each phase must show results before the next begins.</div>
          <div class="insight"><strong>The plan is the contract.</strong> Apply only from a saved plan file. The gap between plan and apply is where drift lives.</div>
          <div class="insight"><strong>Blast radius matters.</strong> Every shared resource change must document what breaks if the apply fails midway.</div>
          <div class="insight"><strong>Destruction needs a second approval.</strong> Any plan showing resource destruction requires explicit re-approval before apply.</div>
        </div>

        <div class="footer">
          Beldine Oluoch &nbsp;·&nbsp; github.com/Bels3/30-day-terraform-challenge &nbsp;·&nbsp; Terraform v1.14.7
        </div>
      </div>
    </body>
    </html>
    HTML
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-instance"
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
      Owner       = "beldine-oluoch"
      Day         = "21"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "webserver" {
  name                = "${var.cluster_name}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.webserver.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.webserver.id
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

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }
}

# ALB, target group, listener
# depends_on on listener enforces correct destroy order
resource "aws_lb" "webserver" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.cluster_name}-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
    Day         = "21"
  }
}

resource "aws_lb_target_group" "webserver" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.cluster_name}-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }

  # Explicit dependency fixes Day 18 destroy-order incident
  depends_on = [aws_lb_target_group.webserver]
}

# SNS topic for all alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-alerts"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
  }
}

# CloudWatch alarms
# Existing: high CPU (80%), unhealthy hosts
# NEW (Day 21 change): ALB request count alarm
#   + aws_cloudwatch_metric_alarm.high_request_count (new)
#   + aws_cloudwatch_dashboard.webserver (new)
#   ~ aws_sns_topic_policy.alerts (updated to allow CloudWatch publish)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU above 80% for 4 minutes scale or investigate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver.name
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
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
  alarm_description   = "Unhealthy hosts in target group check instances"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.webserver.arn_suffix
    TargetGroup  = aws_lb_target_group.webserver.arn_suffix
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

# NEW — Day 21 feature branch change
# ALB request count alarm: fires when requests drop to zero
resource "aws_cloudwatch_metric_alarm" "zero_requests" {
  alarm_name          = "${var.cluster_name}-zero-requests"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "No requests to ALB for 5 minutes cluster may be unreachable"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.webserver.arn_suffix
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    AddedOn     = "day21"
  }
}

# NEW — Day 21 feature branch change
# CloudWatch dashboard — visualises all three alarms in one view
resource "aws_cloudwatch_dashboard" "webserver" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "CPU Utilization"
          region = var.region
          period = 120
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.webserver.name]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB Request Count"
          region = var.region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.webserver.arn_suffix]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Unhealthy Host Count"
          region = var.region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.webserver.arn_suffix, "TargetGroup", aws_lb_target_group.webserver.arn_suffix]
          ]
        }
      }
    ]
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "webserver" {
  name              = "/aws/ec2/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
  }
}
