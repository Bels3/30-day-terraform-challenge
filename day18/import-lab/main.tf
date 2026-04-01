terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "fortress_state" {
  bucket        = "s3-fortress-state"
  force_destroy = false

  tags = {
    Name        = "Terraform State Bucket"
    Description = "Stores Terraform state files"
    Environment = "shared"
    ManagedBy   = "Terraform"
    Project     = "S3SecurityFortress"
    Purpose     = "TerraformBackend"
  }
}

resource "aws_dynamodb_table" "fortress_locks" {
  name         = "s3-fortress-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Description = "Prevents concurrent state modifications"
    Environment = "shared"
    ManagedBy   = "Terraform"
    Project     = "S3SecurityFortress"
    Purpose     = "TerraformBackend"
  }
}
