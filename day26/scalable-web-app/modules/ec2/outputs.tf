output "launch_template_id" {
  description = "ID of the EC2 launch template"
  value       = aws_launch_template.web.id
}

output "launch_template_arn" {
  description = "ARN of the EC2 launch template"
  value       = aws_launch_template.web.arn
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.web.latest_version
}

output "security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance.id
}

output "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  value       = aws_iam_instance_profile.ec2_cloudwatch.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2"
  value       = aws_iam_role.ec2_cloudwatch.arn
}
