output "upper_names" {
  description = "Uppercase transformation of user names"
  value       = [for name in var.user_names : upper(name)]
}

output "count_user_arns" {
  description = "Map of username to ARN from count example"
  value = {
    for user in aws_iam_user.count_example :
    user.name => user.arn
  }
}

output "foreach_user_arns" {
  description = "Map of username to ARN from for_each map example"
  value = {
    for name, user in aws_iam_user.foreach_map_example :
    name => user.arn
  }
}

output "instance_type" {
  description = "Instance type selected based on environment"
  value       = local.instance_type
}

output "autoscaling_enabled" {
  description = "Whether autoscaling is enabled"
  value       = var.enable_autoscaling
}
