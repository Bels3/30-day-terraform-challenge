terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud backend — Day 20
  # Run: terraform login && terraform init to migrate state
  cloud {
    organization = "beldine-terraform"

    workspaces {
      name = "webserver-cluster-dev"
    }
  }
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
  description = "Security group for ASG instances"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.cluster_name}-instance-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
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
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
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

# Launch template — v3 response (Day 20 change)
# This is the change made in Step 2 of the seven-step workflow.
# Previous: "Hello from webserver v2"
# Current:  "Hello from webserver v3 — Day 20"
resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  # IMDSv2 enforced — no IMDSv1 allowed
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
  <title>Day 20 — Terraform Deployment Workflow</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0d1117; color: #e6edf3; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 2rem; }
    .card { background: #161b27; border: 1px solid #30363d; border-radius: 12px; max-width: 720px; width: 100%; padding: 2.5rem; }
    .badge { display: inline-block; background: #ff9900; color: #0d1117; font-weight: 700; font-size: 0.75rem; padding: 0.25rem 0.75rem; border-radius: 999px; letter-spacing: 0.05em; margin-bottom: 1.25rem; }
    h1 { font-size: 1.75rem; font-weight: 700; color: #ff9900; margin-bottom: 0.5rem; }
    .subtitle { color: #8b949e; font-size: 0.95rem; margin-bottom: 2rem; }
    .section { margin-bottom: 1.75rem; }
    .section-title { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; color: #ff9900; margin-bottom: 0.75rem; }
    .steps { display: grid; grid-template-columns: 1fr 1fr; gap: 0.6rem; }
    .step { background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 0.6rem 0.85rem; font-size: 0.82rem; display: flex; align-items: center; gap: 0.5rem; }
    .step-num { color: #ff9900; font-weight: 700; font-family: monospace; }
    .step-text { color: #e6edf3; }
    .insight { background: #0d1117; border-left: 3px solid #ff9900; border-radius: 0 8px 8px 0; padding: 0.85rem 1rem; font-size: 0.85rem; color: #8b949e; line-height: 1.6; margin-bottom: 0.6rem; }
    .insight span { color: #e6edf3; font-weight: 600; }
    .meta { display: flex; gap: 1rem; flex-wrap: wrap; }
    .meta-item { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: 0.4rem 0.75rem; font-family: monospace; font-size: 0.78rem; color: #3fb950; }
    .footer { margin-top: 2rem; padding-top: 1.25rem; border-top: 1px solid #30363d; font-size: 0.75rem; color: #8b949e; display: flex; justify-content: space-between; flex-wrap: wrap; gap: 0.5rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">DAY 20 — 30-DAY TERRAFORM CHALLENGE</div>
    <h1>Application Deployment Workflow</h1>
    <p class="subtitle">Seven steps from a developer's laptop to production — mapped to Infrastructure as Code.</p>

    <div class="section">
      <div class="section-title">The Seven-Step Workflow</div>
      <div class="steps">
        <div class="step"><span class="step-num">01</span><span class="step-text">Version Control</span></div>
        <div class="step"><span class="step-num">02</span><span class="step-text">Run Locally</span></div>
        <div class="step"><span class="step-num">03</span><span class="step-text">Make Code Changes</span></div>
        <div class="step"><span class="step-num">04</span><span class="step-text">Submit for Review</span></div>
        <div class="step"><span class="step-num">05</span><span class="step-text">Automated Tests</span></div>
        <div class="step"><span class="step-num">06</span><span class="step-text">Merge and Release</span></div>
        <div class="step"><span class="step-num">07</span><span class="step-text">Deploy</span></div>
        <div class="step"><span class="step-num">✓</span><span class="step-text">All Steps Complete</span></div>
      </div>
    </div>

    <div class="section">
      <div class="section-title">Key Insights</div>
      <div class="insight"><span>terraform plan is not a running app.</span> It shows exactly what will change in real cloud infrastructure before a single resource is touched.</div>
      <div class="insight"><span>The state file is not in Git.</span> Unlike application code, Terraform state lives in a remote backend — S3 with locking, or Terraform Cloud.</div>
      <div class="insight"><span>Infrastructure tests cost real money.</span> Every integration test spins up real AWS resources. Plan output in a PR is the reviewer's window into production impact.</div>
    </div>

    <div class="section">
      <div class="section-title">Cluster Metadata</div>
      <div class="meta">
        <div class="meta-item">cluster: webserver-cluster-dev</div>
        <div class="meta-item">env: dev</div>
        <div class="meta-item">region: eu-west-1</div>
        <div class="meta-item">version: v3</div>
        <div class="meta-item">day: 20</div>
      </div>
    </div>

    <div class="footer">
      <span>Beldine Oluoch · eu-west-1 · Terraform v1.14.7</span>
      <span>#30DayTerraformChallenge</span>
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

  depends_on = [aws_lb_target_group.webserver]
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU above 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

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
  alarm_description   = "Unhealthy hosts detected in target group"
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

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-alerts"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = "beldine-oluoch"
  }
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
