variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ALB (minimum 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets across different AZs are required for high availability."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "server_port" {
  description = "Port the backend instances listen on"
  type        = number
  default     = 80
}

variable "instance_security_group_id" {
  description = "Security group ID of EC2 instances (for ingress rules)"
  type        = string
}

variable "project_name" {
  description = "Project identifier for resource naming"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection (recommended for prod)"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout for ALB connections in seconds"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs (optional)"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Prefix for ALB access logs in S3"
  type        = string
  default     = null
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener (optional)"
  type        = string
  default     = null
}
