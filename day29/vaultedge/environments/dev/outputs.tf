# VaultEdge · environments/dev/outputs.tf

# WHY THIS MATTERS — root module outputs
# Root module outputs are displayed in the terminal after terraform apply
# completes. They are also stored in state and readable via terraform output.

# Run after apply:
#   terraform output                    → shows all non-sensitive outputs
#   terraform output network_id         → shows specific output value
#   terraform output -json              → full JSON including sensitive values
#   terraform output -raw api_key       → prints raw sensitive value

output "network_id" {
  description = "Unique identifier for the dev network."
  value       = module.network.network_id
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = module.network.subnet_ids
}

output "service_ids" {
  description = "Map of service name to service ID."
  value       = module.app.service_ids
}

output "service_labels" {
  description = "List of fully-qualified service labels."
  value       = module.app.service_labels
}

output "api_key" {
  description = "Generated API key — sensitive, will be redacted in output."
  value       = module.app.api_key
  sensitive   = true
}

output "environment_label" {
  description = "Full environment label from the network module."
  value       = module.network.environment_label
}

output "generated_files" {
  description = "Paths to all generated configuration files."
  value = {
    network_manifest  = module.network.manifest_path
    app_config        = module.app.config_path
    deploy_manifest   = module.app.deploy_manifest_path
    summary           = local_file.deployment_summary.filename
  }
}
