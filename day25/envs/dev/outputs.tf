output "website_url" {
  value       = "https://${module.static_website.cloudfront_domain_name}"
  description = "Live website URL — HTTPS via CloudFront"
}

output "cloudfront_distribution_id" {
  value       = module.static_website.cloudfront_distribution_id
  description = "Use this ID to invalidate the CloudFront cache after content updates"
}

output "bucket_name" {
  value       = module.static_website.bucket_name
  description = "S3 bucket name — use for aws s3 sync operations"
}

output "s3_website_endpoint" {
  value       = "http://${module.static_website.website_endpoint}"
  description = "Direct S3 website endpoint — HTTP only, bypass CloudFront"
}
