# Required — no defaults
variable "cluster_name" {
  description = "Name for the cluster and all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

# Safe defaults
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "Port the ALB listens on"
  type        = number
  default     = 80
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage to trigger alarm"
  type        = number
  default     = 80
}
