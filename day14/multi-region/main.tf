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

# Default provider — primary region eu-west-1 

provider "aws" {
  region = var.primary_region
}

# Aliased provider — replica region eu-west-2

provider "aws" {
  alias  = "eu_west_2"
  region = var.replica_region
}

# Primary S3 bucket — eu-west-1 

resource "aws_s3_bucket" "primary" {
  bucket = "${var.bucket_prefix}-primary"
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replica S3 bucket — eu-west-2

resource "aws_s3_bucket" "replica" {
  provider = aws.eu_west_2
  bucket   = "${var.bucket_prefix}-replica"
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.eu_west_2
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for replication

resource "aws_iam_role" "replication" {
  name = "day14-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "day14-s3-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = ["${aws_s3_bucket.replica.arn}/*"]
      }
    ]
  })
}

# Replication configuration 

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.primary]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}

# Multi-Account Setup — Single Account Documentation
#
# With multiple AWS accounts, each account gets its own aliased
# provider using assume_role. Terraform assumes the specified IAM
# role in each target account before making API calls.
#
# provider "aws" {
#   alias  = "production"
#   region = "eu-west-1"
#
#   assume_role {
#     role_arn     = "arn:aws:iam::111111111111:role/TerraformDeployRole"
#     session_name = "TerraformSession"
#   }
# }
#
# provider "aws" {
#   alias  = "staging"
#   region = "eu-west-1"
#
#   assume_role {
#     role_arn     = "arn:aws:iam::222222222222:role/TerraformDeployRole"
#     session_name = "TerraformSession"
#   }
# }
#
# Resources in each account reference their provider explicitly:
#
# resource "aws_s3_bucket" "prod_bucket" {
#   provider = aws.production
#   bucket   = "my-production-bucket"
# }
#
# resource "aws_s3_bucket" "staging_bucket" {
#   provider = aws.staging
#   bucket   = "my-staging-bucket"
# }
#
# TerraformDeployRole in each target account needs:
# 1. Trust policy allowing the calling account to assume it
# 2. Permissions for whatever resources Terraform manages
#
# Trust policy example:
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Effect": "Allow",
#     "Principal": {
#       "AWS": "arn:aws:iam::CALLING_ACCOUNT_ID:root"
#     },
#     "Action": "sts:AssumeRole"
#   }]
# }
