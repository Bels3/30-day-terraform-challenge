output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "scale_out_policy_arn" {
  description = "ARN of the CPU scale-out policy"
  value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  description = "ARN of the CPU scale-in policy"
  value       = aws_autoscaling_policy.scale_in.arn
}

output "target_tracking_policy_arn" {
  description = "ARN of the target tracking policy"
  value       = aws_autoscaling_policy.cpu_target_tracking.arn
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.web_asg.dashboard_name}"
}
