#terraform {
#  required_version = ">= 1.0.0"

#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 5.0"
#   }
#  }
#  backend "s3" {}
#}

#provider "aws" {
#  alias  = "primary"
#  region = "eu-west-1"
#}

#provider "aws" {
#  alias  = "replica"
#  region = "eu-west-2"
#}

#module "multi_region_app" {
#  source   = "../modules/multi-region-app"
#  app_name = "beldine"

#  providers = {
#    aws.primary = aws.primary
#    aws.replica = aws.replica
#  }
#}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {}
}

# Default provider — eu-west-1
provider "aws" {
  region = "eu-west-1"
}

# Aliased provider — eu-west-2
provider "aws" {
  alias  = "replica"
  region = "eu-west-2"
}

module "multi_region_app" {
  source   = "../modules/multi-region-app"
  app_name = "beldine-v6"

  providers = {
    aws.primary = aws
    aws.replica = aws
  }
}

resource "aws_s3_bucket" "ireland" {
  bucket = "beldine-v6-ireland"
  region = "eu-west-1"
}

resource "aws_s3_bucket" "london" {
  bucket = "beldine-v6-london"
  region = "eu-west-2"
}
