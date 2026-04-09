variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}

variable "cluster_name" {
  description = "Name prefix for all cluster resources"
  type        = string
  default     = "day21-webserver"
}

variable "instance_type" {
  description = "EC2 instance type — t2 or t3 family only"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "instance_type must be in the t2 or t3 family."
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu, eu-west-1)"
  type        = string
  default     = "ami-03957e4cfe042cca1"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be >= min_size."
  }
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 80
}

variable "alb_port" {
  description = "Port the ALB listens on"
  type        = number
  default     = 80
}

variable "project_name" {
  description = "Project tag applied to all resources"
  type        = string
  default     = "terraform-30-day-challenge"
}
