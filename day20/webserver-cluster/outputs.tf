output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.webserver.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.webserver.name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "instance_security_group_id" {
  description = "Security group ID of the ASG instances"
  value       = aws_security_group.instance.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.webserver.name
}

output "app_version" {
  description = "Application version deployed in this cluster"
  value       = "v3"
}
