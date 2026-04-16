output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = aws_lb.web.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.web.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  value       = aws_lb_target_group.web.arn_suffix
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if configured)"
  value       = var.ssl_certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "high_request_alarm_arn" {
  description = "ARN of the high request count CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.high_request_count.arn
}
