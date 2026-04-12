output "bucket_name" {
  value       = aws_s3_bucket.website.id
  description = "Name of the S3 bucket hosting the website"
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "ARN of the S3 bucket"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "S3 static website endpoint — HTTP only, not for production use"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.website.domain_name
  description = "CloudFront distribution domain name — primary access URL (HTTPS)"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.website.id
  description = "CloudFront distribution ID — use for cache invalidation"
}

output "cloudfront_arn" {
  value       = aws_cloudfront_distribution.website.arn
  description = "CloudFront distribution ARN"
}
