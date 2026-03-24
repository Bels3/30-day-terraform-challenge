terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"
}

locals {
  is_production = var.environment == "production"

  instance_type     = local.is_production ? "t2.medium" : "t2.micro"
  min_size          = local.is_production ? 3 : 1
  max_size          = local.is_production ? 10 : 3
  enable_monitoring = local.is_production
}

# BROWNFIELD: Lookup existing VPC by tag
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["existing-vpc"]
  }
}

# GREENFIELD: Create new VPC
resource "aws_vpc" "new" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "${var.cluster_name}-${var.environment}-vpc"
  }
}

locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id
}

resource "aws_security_group" "web" {
  name        = "${var.cluster_name}-${var.environment}-sg"
  description = "Security group for ${var.environment} environment"
  vpc_id      = local.vpc_id

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
    Name        = "${var.cluster_name}-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_detailed_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80% in ${var.environment}"
}
