output "primary_alb_url" {
  description = "Primary region ALB URL"
  value       = "http://${module.alb_primary.alb_dns_name}"
}

output "secondary_alb_url" {
  description = "Secondary region ALB URL"
  value       = "http://${module.alb_secondary.alb_dns_name}"
}

output "rds_primary_endpoint" {
  description = "Primary RDS endpoint"
  value       = module.rds_primary.db_endpoint
  sensitive   = true
}

output "rds_replica_endpoint" {
  description = "Replica RDS endpoint"
  value       = module.rds_replica.db_endpoint
  sensitive   = true
}

output "primary_asg_name" {
  description = "Primary region ASG name"
  value       = module.asg_primary.asg_name
}

output "secondary_asg_name" {
  description = "Secondary region ASG name"
  value       = module.asg_secondary.asg_name
}
