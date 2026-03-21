provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = "terraform-state-beldine-2026"
    key    = "environments/dev/terraform.tfstate"
    region = "eu-west-1"
  }
}

output "dev_sg_id_from_remote_state" {
  value       = data.terraform_remote_state.dev.outputs.sg_id
  description = "Dev security group ID read from remote state"
}

resource "aws_security_group" "web" {
  name        = "terraform-day7-filelayout-staging-sg"
  description = "Staging environment security group"

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
    Name        = "terraform-day7-filelayout-staging-sg"
    Environment = var.environment
  }
}

output "security_group_id" {
  value       = aws_security_group.web.id
  description = "Staging security group ID"
}

output "environment" {
  value       = var.environment
  description = "Environment name"
}
