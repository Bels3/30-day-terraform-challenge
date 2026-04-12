variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a lowercase letter or digit, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "owner" {
  description = "Owner of this resource — used for tagging and accountability"
  type        = string
}

variable "project_name" {
  description = "Project name — used for tagging and naming conventions"
  type        = string
}

variable "index_document" {
  description = "The index document filename served at the bucket root"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error document filename served for 4xx responses"
  type        = string
  default     = "error.html"
}

variable "price_class" {
  description = "CloudFront price class — controls which edge locations serve content"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_ttl" {
  description = "Default CloudFront cache TTL in seconds"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum CloudFront cache TTL in seconds"
  type        = number
  default     = 86400
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
