terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Day 19 import lab uses local state intentionally.
  # The resource being imported IS the remote state bucket,
  # so bootstrapping it into itself would create a circular dependency.
  # In a real adoption scenario you would either:
  #   a) use a separate "bootstrap" state bucket, or
  #   b) accept local state for the state-bucket-management layer only.
}

provider "aws" {
  region = "eu-west-1"
}

# ---------------------------------------------------------------------------
# Imported resource: the S3 bucket that backs all remote Terraform state.
# This bucket already exists and was created manually on Day 2.
# It was NOT previously managed by any Terraform configuration.

# Import command used:
#   terraform import aws_s3_bucket.terraform_state terraform-state-beldine-2026
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-beldine-2026"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "terraform-30-day-challenge"
    Owner       = "beldine-oluoch"
    Purpose     = "remote-state-storage"
    ImportedOn  = "day19"
  }
}

# Versioning must match what is already enabled on the bucket.
# Disabling versioning on a state bucket is a production incident waiting to happen.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption at rest — bucket was created with AES256.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access. A public state bucket leaks IAM ARNs,
# resource IDs, and sometimes secrets stored in outputs.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "state_bucket_name" {
  description = "Name of the imported S3 state bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the imported S3 state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "versioning_status" {
  description = "Versioning configuration on the state bucket"
  value       = aws_s3_bucket_versioning.terraform_state.versioning_configuration[0].status
}
