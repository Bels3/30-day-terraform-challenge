terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day06/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "terraform-day6-example-beldine-2026"

  tags = {
    Name        = "terraform-day6-example"
    Environment = "learning"
    Challenge   = "30-day-terraform"
  }
}

resource "aws_security_group" "example" {
  name        = "terraform-day6-sg"
  description = "Day 6 example security group"

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
    Name = "terraform-day6-sg"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.example.id
  description = "Example S3 bucket name"
}

output "security_group_id" {
  value       = aws_security_group.example.id
  description = "Example security group ID"
}
