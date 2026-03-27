terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  alias  = "primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "replica"
  region = "eu-west-2"
}

module "multi_region_app" {
  source   = "../modules/multi-region-app"
  app_name = "beldine"

  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
