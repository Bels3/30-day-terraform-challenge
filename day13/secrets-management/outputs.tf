output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.example.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.example.db_name
}

output "secret_arn" {
  description = "ARN of the secret in Secrets Manager"
  value       = data.aws_secretsmanager_secret.db_credentials.arn
}
