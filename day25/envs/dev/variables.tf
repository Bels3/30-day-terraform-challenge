variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "owner" {
  description = "Owner identifier for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and resource naming"
  type        = string
}

variable "index_document" {
  description = "Index document filename"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document filename"
  type        = string
  default     = "error.html"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
