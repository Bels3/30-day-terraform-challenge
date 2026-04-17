terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}
