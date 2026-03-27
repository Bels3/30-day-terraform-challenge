output "primary_bucket_name" {
  description = "Name of the primary S3 bucket in eu-west-1"
  value       = aws_s3_bucket.primary.id
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket in eu-west-2"
  value       = aws_s3_bucket.replica.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket"
  value       = aws_s3_bucket.replica.arn
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for S3 replication"
  value       = aws_iam_role.replication.arn
}
