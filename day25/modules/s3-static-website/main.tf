locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.owner
  })
}

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = var.environment != "production"
  tags          = local.common_tags
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "website" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}

resource "aws_cloudwatch_log_group" "cloudfront_access" {
  name              = "/aws/cloudfront/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = var.index_document
  price_class         = var.price_class
  tags                = local.common_tags

  comment = "${var.project_name} ${var.environment} — managed by Terraform Day 25"

  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "s3-website-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content_type = "text/html; charset=utf-8"
  source       = "${path.module}/../../templates/index.html"
  etag         = filemd5("${path.module}/../../templates/index.html")

  tags = local.common_tags
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content_type = "text/html; charset=utf-8"
  source       = "${path.module}/../../templates/error.html"
  etag         = filemd5("${path.module}/../../templates/error.html")

  tags = local.common_tags
}
