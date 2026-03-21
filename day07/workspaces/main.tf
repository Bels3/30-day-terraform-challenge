terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day07/workspaces/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type per environment"
  type        = map(string)
  default = {
    dev        = "t2.micro"
    staging    = "t2.micro"
    production = "t2.micro"
  }
}

resource "aws_security_group" "web" {
  name        = "terraform-day7-${terraform.workspace}-sg"
  description = "Security group for ${terraform.workspace} environment"

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
    Name        = "terraform-day7-${terraform.workspace}-sg"
    Environment = terraform.workspace
  }
}

output "environment" {
  value = terraform.workspace
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "security_group_name" {
  value = aws_security_group.web.name
}
