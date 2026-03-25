output "alb_dns_name" {
  description = "DNS name of the load balancer — use this to test in browser and traffic loop"
  value       = aws_lb.example.dns_name
}

output "active_environment" {
  description = "Which environment is currently receiving traffic"
  value       = var.active_environment
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}
