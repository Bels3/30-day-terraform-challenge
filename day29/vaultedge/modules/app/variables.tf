# VaultEdge · modules/app/variables.tf

variable "project_name" {
  description = "Project name prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "network_id" {
  description = <<-EOT
    Network ID from the network module output.
    This demonstrates consuming a child module output in another module call.
    In the root module: network_id = module.network.network_id
  EOT
  type = string
}

variable "services" {
  description = <<-EOT
    List of application services to configure.
    Each service gets a unique ID via for_each and appears in the config file.
  EOT
  type = list(object({
    name     = string
    port     = number
    replicas = number
  }))
  default = []
}
