# VARIABLES DEFINITION
# All variables used across the VPC, EC2, ALB, and ASG modules
# Following established patterns from Days 1-25
# REQUIRED VARIABLES (No Defaults - Must be set in terraform.tfvars)

variable "cluster_name" {
  description = "Name of the web cluster (used for resource naming)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "owner" {
  description = "Owner tag value for resource tracking"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 LTS recommended)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the web tier"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number

  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

# ================================================
# VARIABLES WITH SAFE DEFAULTS
# ================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 80
}

variable "desired_capacity" {
  description = "Desired number of instances at launch"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "Desired capacity must be between min_size and max_size."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cpu_alarm_threshold" {
  description = "CPU threshold percentage for scale-out alarm"
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "cpu_scale_out_threshold" {
  description = "Average CPU % at which to add one instance"
  type        = number
  default     = 70
}

variable "cpu_scale_in_threshold" {
  description = "Average CPU % at which to remove one instance"
  type        = number
  default     = 30
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds after scale-out"
  type        = number
  default     = 300
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds after scale-in"
  type        = number
  default     = 300
}

variable "health_check_grace_period" {
  description = "Grace period in seconds for health checks on new instances"
  type        = number
  default     = 300
}

variable "enable_scale_in_protection" {
  description = "Enable scale-in protection for instances"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout for ALB connections in seconds"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Prefix for ALB access logs in S3"
  type        = string
  default     = null
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
  default     = null
}

variable "request_count_threshold" {
  description = "Request count threshold for scaling alarm"
  type        = number
  default     = 1000
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for scaling notifications"
  type        = string
  default     = null
}
