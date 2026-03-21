provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "web" {
  name        = "terraform-day7-filelayout-dev-sg"
  description = "Dev environment security group"

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
    Name        = "terraform-day7-filelayout-dev-sg"
    Environment = var.environment
  }
}

output "security_group_id" {
  value       = aws_security_group.web.id
  description = "Dev security group ID"
}

output "environment" {
  value       = var.environment
  description = "Environment name"
}
