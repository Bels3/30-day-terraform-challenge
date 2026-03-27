variable "primary_region" {
  description = "Primary AWS region for the source S3 bucket"
  type        = string
  default     = "eu-west-1"
}

variable "replica_region" {
  description = "Secondary AWS region for the replica S3 bucket"
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket names — must be globally unique"
  type        = string
  default     = "beldine-day14"
}
