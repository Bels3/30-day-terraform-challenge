# Required (No Defaults)
variable "app_name" { type = string }
variable "environment" { type = string }
variable "primary_ami_id" { type = string }
variable "secondary_ami_id" { type = string }
variable "hosted_zone_id" { type = string }
variable "domain_name" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}

# Optional (With Defaults)
variable "primary_region" { default = "eu-west-1" }
variable "secondary_region" { default = "us-west-2" }
variable "primary_vpc_cidr" { default = "10.0.0.0/16" }
variable "secondary_vpc_cidr" { default = "10.1.0.0/16" }
variable "primary_public_subnet_cidrs" { default = ["10.0.1.0/24", "10.0.2.0/24"] }
variable "secondary_public_subnet_cidrs" { default = ["10.1.1.0/24", "10.1.2.0/24"] }
variable "primary_private_subnet_cidrs" { default = ["10.0.11.0/24", "10.0.12.0/24"] }
variable "secondary_private_subnet_cidrs" { default = ["10.1.11.0/24", "10.1.12.0/24"] }
variable "primary_availability_zones" { default = ["eu-west-1a", "eu-west-1b"] }
variable "secondary_availability_zones" { default = ["us-west-2a", "us-west-2b"] }
variable "instance_type" { default = "t3.micro" }
variable "min_size" { default = 1 }
variable "max_size" { default = 4 }
variable "desired_capacity" { default = 2 }
