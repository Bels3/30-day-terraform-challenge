variable "region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "cluster_name" {
  type        = string
  description = "Name prefix for all resources in this cluster"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the webserver"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must be a t2 or t3 family type."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances in the ASG"

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the ASG"

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used in tagging"
  default     = "30-day-terraform-challenge"
}

variable "team_name" {
  type        = string
  description = "Team or owner name used in tagging"
  default     = "beldine"
}

variable "server_port" {
  type        = number
  description = "Port the web server listens on"
  default     = 80
}

variable "alb_port" {
  type        = number
  description = "Port the ALB listens on"
  default     = 80
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instances"
  default     = "ami-03957e4cfe042cca1"
}
