provider "aws" {
  region = var.region
}

data "aws_availability_zones" "all" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "terraform-day4-instance-sg"
  description = "Allow HTTP traffic on server port"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-day4-instance-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "terraform-day4-alb-sg"
  description = "Allow HTTP traffic to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-day4-alb-sg"
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "terraform-day4-"
  image_id      = "ami-0c38b837cd80f13bb"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              cat > index.html <<-HTML
              <!DOCTYPE html>
              <html>
                <head>
                  <title>Beldine | Terraform Day 4</title>
                  <style>
                    body {
                      font-family: Arial, sans-serif;
                      display: flex;
                      justify-content: center;
                      align-items: center;
                      height: 100vh;
                      margin: 0;
                      background: #232f3e;
                      color: white;
                      text-align: center;
                    }
                    h1 { font-size: 2.5em; margin-bottom: 10px; }
                    p  { font-size: 1.2em; color: #ff9900; margin: 5px 0; }
                  </style>
                </head>
                <body>
                  <div>
                    <h1>Beldine's Infrastructure Journey</h1>
                    <p>Day 4 - Clustered Web Server</p>
                    <p>EveOps | Meru HashiCorp User Group | 30-Day Terraform Challenge</p>
                  </div>
                </body>
              </html>
              HTML
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terraform-day4-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "terraform-day4-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size = 2
  max_size = 5

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-day4-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web" {
  name               = "terraform-day4-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "terraform-day4-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "terraform-day4-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "DNS name of the Application Load Balancer"
}
