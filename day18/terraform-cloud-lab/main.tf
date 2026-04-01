terraform {
  required_version = ">= 1.10"

  cloud {
    organization = "beldine-terraform"

    workspaces {
      name = "day18-terraform-cloud"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

output "lab_complete" {
  value = "Terraform Cloud backend configured successfully for Day 18"
}
