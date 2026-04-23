# VaultEdge · environments/prod/outputs.tf

output "network_id" {
  description = "Unique identifier for the prod network."
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
  description = "Generated API key — sensitive."
  value       = module.app.api_key
  sensitive   = true
}

output "environment_label" {
  description = "Full environment label."
  value       = module.network.environment_label
}

output "generated_files" {
  description = "Paths to all generated configuration files."
  value = {
    network_manifest = module.network.manifest_path
    app_config       = module.app.config_path
    deploy_manifest  = module.app.deploy_manifest_path
    summary          = local_file.deployment_summary.filename
  }
}
