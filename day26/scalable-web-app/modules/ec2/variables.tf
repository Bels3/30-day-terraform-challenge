variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "server_port" {
  description = "Port for web server"
  type        = number
  default     = 80
}

variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "volume_size" {
  description = "Root EBS volume size"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 4
}

variable "alb_security_group_id" {
  description = "ALB security group ID to allow HTTP traffic from"
  type        = string
  default     = null
}
