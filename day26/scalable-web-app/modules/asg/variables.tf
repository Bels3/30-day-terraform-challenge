variable "name" {
  description = "Name prefix for ASG resources"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the EC2 launch template"
  type        = string
}

variable "launch_template_version" {
  description = "Version of the EC2 launch template"
  type        = string
  default     = "$Latest"
}

variable "subnet_ids" {
  description = "List of private subnet IDs for ASG instances"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets across different AZs are required."
  }
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs to attach"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
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

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "cpu_scale_out_threshold" {
  description = "Average CPU % threshold for scaling out"
  type        = number
  default     = 70
}

variable "cpu_scale_in_threshold" {
  description = "Average CPU % threshold for scaling in"
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
  description = "Grace period in seconds for health checks"
  type        = number
  default     = 300
}

variable "enable_scale_in_protection" {
  description = "Enable scale-in protection for instances (prod only)"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for scaling notifications (optional)"
  type        = string
  default     = null
}


variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "enable_request_based_scaling" {
  description = "Enable request count based scaling (requires ALB alarm)"
  type        = bool
  default     = false
}
