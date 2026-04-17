locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "multi-region-ha"
    Owner       = "Beldine"
    Day         = "27"
    Region      = var.region
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "template_file" "dashboard" {
  template = file("${path.module}/templates/dashboard.html.tpl")
  vars = {
    environment       = var.environment
    primary_region    = var.region
    secondary_region  = var.secondary_region
    min_size          = var.min_size
    max_size          = var.max_size
    az_list           = join(", ", var.availability_zones)
    secondary_az_list = join(", ", var.secondary_availability_zones)
    domain_name       = var.domain_name
    timestamp         = formatdate("HH:mm:ss 'UTC'", timestamp())
  }
}



resource "aws_security_group" "instance" {
  name        = "web-instance-sg-${var.environment}-${var.region}"
  description = "Allow inbound from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-lt-${var.environment}-${var.region}-"
  image_id      = data.aws_ami.ubuntu.id 
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

      user_data = base64encode(<<-USERDATA
    #!/bin/bash
    apt update -y
    apt install -y apache2
    
    cat > /var/www/html/index.html << 'DASHBOARD'
    ${data.template_file.dashboard.rendered}
    DASHBOARD
    
    echo "OK" > /var/www/html/health
    
    systemctl start apache2
    systemctl enable apache2
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "web-${var.environment}-${var.region}" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "web-asg-${var.environment}-${var.region}"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "web-${var.environment}-${var.region}" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "web-scale-out-${var.environment}-${var.region}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "web-scale-in-${var.environment}-${var.region}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "web-cpu-high-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
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
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "web-cpu-low-${var.environment}-${var.region}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
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
}
