# OUTPUTS - DAY 26
# Networking Outputs
output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.availability_zones
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_gateway_public_ips
}

# Application Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "Full URL to access the web application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = module.ec2.launch_template_id
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = module.alb.target_group_arn
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard"
  value       = module.asg.dashboard_url
}

# Deployment Summary
output "deployment_info" {
  description = "Deployment summary information"
  value = {
    environment      = var.environment
    region           = var.aws_region
    vpc_id           = module.vpc.vpc_id
    min_size         = var.min_size
    max_size         = var.max_size
    desired_capacity = var.desired_capacity
    instance_type    = var.instance_type
    deployed_by      = var.owner
    day              = "26"
  }
}
