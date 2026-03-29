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
  region = "eu-west-1"
}

resource "aws_sns_topic" "test" {
  name = "day17-state-migration-test"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "30-day-terraform-challenge"
  }
}

output "sns_topic_arn" {
  value = aws_sns_topic.test.arn
}
