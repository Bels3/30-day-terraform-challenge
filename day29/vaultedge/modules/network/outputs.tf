# VaultEdge · modules/network/outputs.tf
# WHY THIS MATTERS — outputs are the ONLY way a child module exposes values
# to its caller. Without output blocks here, the root module cannot access
# ANY value computed inside this module.

# The calling module accesses outputs as:
#   module.network.network_id
#   module.network.subnet_ids
#   module.network.manifest_path

# This is a hard exam boundary: child module values are PRIVATE unless
# explicitly exposed through output blocks. There is no other mechanism.

output "network_id" {
  description = "Hex identifier for the VaultEdge network in this environment."
  value       = random_id.network_id.hex
}

output "subnet_ids" {
  description = <<-EOT
    Map of subnet name → subnet hex ID.
    Callers access individual subnets as: module.network.subnet_ids["public"]

    WHY THIS MATTERS — outputting a for_each result as a map.
    The value here is computed from for_each, so it is a map.
    Splat expressions (resource[*].attribute) do NOT work on for_each maps.
    Use values(random_id.subnet_id)[*].hex for a list, or access by key.
  EOT
  value = {
    for name, subnet_id in random_id.subnet_id :
    name => subnet_id.hex
  }
}

output "manifest_path" {
  description = "Absolute path to the generated network manifest JSON file."
  value       = local_file.network_manifest.filename
}

output "firewall_rule_count" {
  description = "Number of firewall rules applied to this network."
  value       = length(var.firewall_rules)
}

output "environment_label" {
  description = "Full environment label used across this network's resources."
  # WHY THIS MATTERS — outputting a local value
  # locals are internal to the module. Outputting a local makes its
  # computed value available externally without exposing the logic.
  value = local.env_label
}
