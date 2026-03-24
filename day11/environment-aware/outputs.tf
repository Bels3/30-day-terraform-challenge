output "environment" {
  value       = var.environment
  description = "Active deployment environment"
}

output "instance_type" {
  value       = local.instance_type
  description = "Instance type selected for this environment"
}

output "min_size" {
  value       = local.min_size
  description = "Minimum cluster size for this environment"
}

output "max_size" {
  value       = local.max_size
  description = "Maximum cluster size for this environment"
}

output "security_group_id" {
  value       = aws_security_group.web.id
  description = "Security group ID"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "VPC ID in use"
}

# SAFE REFERENCE: Returns null when monitoring is disabled
output "alarm_arn" {
  value       = var.enable_detailed_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
  description = "CloudWatch alarm ARN. null if monitoring disabled"
}
