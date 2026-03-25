variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "day12-webserver"
}

variable "ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-03957e4cfe042cca1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 80
}

variable "active_environment" {
  description = "Which environment is currently receiving traffic: blue or green"
  type        = string
  default     = "blue"
}

variable "alb_port" {
  description = "Port the ALB listens on for incoming internet traffic"
  type        = number
  default     = 80
}
