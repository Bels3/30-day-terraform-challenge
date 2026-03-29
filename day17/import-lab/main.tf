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

resource "aws_sns_topic" "imported" {
  name = "day17-manually-created-topic"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "30-day-terraform-challenge"
  }
}

output "imported_topic_arn" {
  value = aws_sns_topic.imported.arn
}
