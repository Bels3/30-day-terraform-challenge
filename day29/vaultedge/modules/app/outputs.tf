# =============================================================================
# VaultEdge · modules/app/outputs.tf
# =============================================================================

output "api_key" {
  description = "Generated API key for this environment."
  value       = random_password.api_key.result

  # WHY THIS MATTERS — sensitive = true on an output
  # This tells Terraform to REDACT this value in CLI output.
  # You will see: api_key = (sensitive value)  in terraform apply output.
  #
  # CRITICAL EXAM DISTINCTIONS:
  #   sensitive = true → redacted in CLI output (plan, apply, terraform output)
  #   sensitive = true → does NOT encrypt the value in the state file
  #   sensitive = true → does NOT prevent the value from being read from state
  #   terraform output -json will still show the value
  #   terraform output api_key will show: "The value is sensitive."
  #   terraform output -raw api_key WILL print the raw value
  #
  # The state file stores it in PLAIN TEXT. Always secure your state file.
  sensitive = true
}

output "service_ids" {
  description = "Map of service name → unique hex identifier."
  value = {
    for name, sid in random_id.service_id :
    name => sid.hex
  }
}

output "config_path" {
  description = "Path to the generated application config file."
  value       = local_file.env_config.filename
}

output "deploy_manifest_path" {
  description = "Path to the generated deployment manifest file."
  value       = local_file.deploy_manifest.filename
}

output "service_labels" {
  description = <<-EOT
    List of fully-qualified service labels.
    WHY THIS MATTERS — this demonstrates extracting values from a for_each
    result as a list using the values() function.
    values(local.service_config) returns the map values as a list.
    You cannot use splat on a for_each map directly.
  EOT
  value = [for config in local.service_config : config.label]
}
