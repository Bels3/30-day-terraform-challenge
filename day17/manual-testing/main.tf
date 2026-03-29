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
    python3 -c "
    html = '''<!DOCTYPE html>
    <html lang=\"en\">
    <head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Day 17 - Manual Testing Suite</title>
    <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{background:#0d1117;font-family:Courier New,monospace;color:#e6edf3;height:100vh;overflow:hidden;display:flex;flex-direction:column;}
    .topbar{background:#161b22;border-bottom:1px solid #21262d;padding:8px 32px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0;}
    .dots{display:flex;gap:6px;align-items:center;}
    .dot{width:9px;height:9px;border-radius:50%;}
    .dot-r{background:#ff5f57;}.dot-y{background:#febc2e;}.dot-g{background:#28c840;}
    .tt{font-size:11px;color:#8b949e;margin-left:10px;}
    .tr2{font-size:11px;color:#3fb950;}
    .hero{padding:14px 32px 8px;flex-shrink:0;}
    .badge{display:inline-flex;align-items:center;gap:5px;background:rgba(63,185,80,0.08);border:1px solid rgba(63,185,80,0.3);border-radius:20px;padding:3px 10px;font-size:10px;color:#3fb950;margin-bottom:6px;}
    h1{font-size:22px;font-weight:700;color:#fff;letter-spacing:-0.5px;}
    h1 span{color:#3fb950;}
    .sub{font-size:11px;color:#8b949e;margin-top:2px;}
    .stats{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:8px 32px;flex-shrink:0;}
    .stat{background:#161b22;border:1px solid #21262d;border-radius:6px;padding:8px 12px;}
    .sl{font-size:9px;text-transform:uppercase;letter-spacing:0.8px;color:#8b949e;margin-bottom:3px;}
    .sv{font-size:18px;font-weight:700;}
    .ss{font-size:10px;color:#8b949e;}
    .green{color:#3fb950;}.orange{color:#ff9900;}.red{color:#f85149;}.blue{color:#58a6ff;}
    .grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;padding:0 32px;flex:1;min-height:0;}
    .sec-hdr{font-size:9px;text-transform:uppercase;letter-spacing:0.8px;color:#8b949e;margin-bottom:6px;padding-bottom:5px;border-bottom:1px solid #21262d;display:flex;justify-content:space-between;}
    .ti{display:flex;align-items:flex-start;gap:8px;background:#161b22;border:1px solid #21262d;border-radius:6px;padding:8px 10px;margin-bottom:5px;}
    .tb{flex-shrink:0;font-size:9px;font-weight:700;padding:2px 6px;border-radius:3px;}
    .pass{background:rgba(63,185,80,0.12);color:#3fb950;border:1px solid rgba(63,185,80,0.3);}
    .fail{background:rgba(248,81,73,0.12);color:#f85149;border:1px solid rgba(248,81,73,0.3);}
    .tn{font-size:11px;color:#c9d1d9;font-weight:700;margin-bottom:2px;}
    .tc{font-size:10px;color:#8b949e;background:#0d1117;border:1px solid #21262d;border-radius:3px;padding:2px 6px;display:inline-block;margin-bottom:2px;}
    .tres{font-size:10px;color:#8b949e;}
    .tres span{color:#3fb950;}
    .tres .bad{color:#f85149;}
    .footer{padding:8px 32px;border-top:1px solid #21262d;display:flex;justify-content:space-between;flex-shrink:0;}
    .fl{font-size:10px;color:#8b949e;}
    .fr{font-size:10px;color:#30363d;}
    </style>
    </head>
    <body>
    <div class=\"topbar\">
    <div class=\"dots\"><span class=\"dot dot-r\"></span><span class=\"dot dot-y\"></span><span class=\"dot dot-g\"></span><span class=\"tt\">manual-test-runner . day17 . eu-west-1</span></div>
    <div class=\"tr2\">LIVE . All systems operational</div>
    </div>
    <div class=\"hero\">
    <div class=\"badge\">DAY 17 . 30-DAY TERRAFORM CHALLENGE</div>
    <h1>Manual <span>Testing</span> Suite</h1>
    <p class=\"sub\">Beldine Oluoch . Structured verification of production-grade infrastructure . github.com/Bels3</p>
    </div>
    <div class=\"stats\">
    <div class=\"stat\"><div class=\"sl\">Total tests</div><div class=\"sv blue\">12</div><div class=\"ss\">4 categories</div></div>
    <div class=\"stat\"><div class=\"sl\">Passed</div><div class=\"sv green\">11</div><div class=\"ss\">91.6% pass rate</div></div>
    <div class=\"stat\"><div class=\"sl\">Failed</div><div class=\"sv red\">1</div><div class=\"ss\">resolved</div></div>
    <div class=\"stat\"><div class=\"sl\">Environment</div><div class=\"sv orange\">dev</div><div class=\"ss\">eu-west-1</div></div>
    </div>
    <div class=\"grid\">
    <div>
    <div class=\"sec-hdr\"><span>Provisioning</span><span class=\"green\">4/4</span></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">terraform init</div><div class=\"tc\">terraform init -backend-config=backend.hcl</div><div class=\"tres\"><span>Successfully initialized</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">terraform validate</div><div class=\"tc\">terraform validate</div><div class=\"tres\"><span>The configuration is valid</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">plan shows 15 resources</div><div class=\"tc\">terraform plan ...</div><div class=\"tres\"><span>Plan: 15 to add, 0 to change, 0 to destroy</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">apply completes cleanly</div><div class=\"tc\">terraform apply -auto-approve</div><div class=\"tres\"><span>Apply complete. 15 added, 0 errors</span></div></div></div>
    <div class=\"sec-hdr\" style=\"margin-top:8px\"><span>State consistency</span><span class=\"green\">2/2</span></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">no changes after apply</div><div class=\"tc\">terraform plan (post-apply)</div><div class=\"tres\"><span>No changes. Infrastructure matches config</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">regression. tag change only</div><div class=\"tc\">terraform plan (after tag edit)</div><div class=\"tres\"><span>1 to change. Nothing unexpected</span></div></div></div>
    </div>
    <div>
    <div class=\"sec-hdr\"><span>Functional verification</span><span class=\"orange\">3/4</span></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">ALB returns 200</div><div class=\"tc\">curl -s http://ALB-DNS</div><div class=\"tres\"><span>200 OK. Expected content returned</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">instances pass health checks</div><div class=\"tc\">aws elbv2 describe-target-health</div><div class=\"tres\"><span>2 of 2 healthy</span></div></div></div>
    <div class=\"ti\"><span class=\"tb fail\">FAIL</span><div><div class=\"tn\">ASG self-healing</div><div class=\"tc\">aws ec2 terminate-instances</div><div class=\"tres bad\">90s gap before replacement. Fix. reduced unhealthy threshold to 2</div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">IMDSv2 enforced</div><div class=\"tc\">curl http://169.254.169.254/...</div><div class=\"tres\"><span>401. Token required. Correct</span></div></div></div>
    <div class=\"sec-hdr\" style=\"margin-top:8px\"><span>Cleanup verification</span><span class=\"green\">2/2</span></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">destroy removes all 15 resources</div><div class=\"tc\">terraform destroy -auto-approve</div><div class=\"tres\"><span>Destroy complete. 15 destroyed</span></div></div></div>
    <div class=\"ti\"><span class=\"tb pass\">PASS</span><div><div class=\"tn\">no orphaned resources in AWS</div><div class=\"tc\">aws ec2 describe-instances --filters ...</div><div class=\"tres\"><span>Empty. Nothing remaining</span></div></div></div>
    </div>
    </div>
    <div class=\"footer\">
    <div class=\"fl\">30-Day Terraform Challenge . Day 17 . Manual Testing . Beldine Oluoch</div>
    <div class=\"fr\">terraform apply . 15 resources . eu-west-1 . 2026</div>
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
    Name    = "${var.cluster_name}-log-group"
  })
}
