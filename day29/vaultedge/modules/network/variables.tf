# VaultEdge · modules/network/variables.tf
# WHY THIS MATTERS — variable declarations are the module's PUBLIC INTERFACE.
# Callers set these. Locals (in main.tf) are PRIVATE — callers cannot touch them.
# If you want a caller to control a value → variable block.
# If you want an internal computed value → locals block.

variable "project_name" {
  description = "The name of the project. Used as a prefix across all resources."
  type        = string

  # WHY THIS MATTERS — variable validation
  # The exam tests that you know validation blocks exist and what they do.
  # condition must evaluate to true for the value to be accepted.
  # error_message is shown to the user if condition is false.
  # This runs BEFORE any provider API calls — pure config-time enforcement.
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "project_name must be between 1 and 20 characters."
  }
}

variable "environment" {
  description = "Deployment environment. Controls naming and resource behaviour."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "subnets" {
  description = "List of subnet definitions. Each becomes a keyed resource via for_each."
  type = list(object({
    name   = string
    cidr   = string
    public = bool
  }))
  default = []
}

variable "firewall_rules" {
  description = <<-EOT
    List of firewall rule objects. Each becomes one entry in the firewall config.

    WHY THIS MATTERS — dynamic blocks iterate this list.
    An empty list produces no firewall rule blocks.
    A list of 5 produces 5 blocks. The configuration adapts to the data.
  EOT
  type = list(object({
    description = string
    port        = number
    protocol    = string
    direction   = string
    allow       = bool
  }))
  default = []
}

variable "icmp_check_count" {
  description = <<-EOT
    Number of ICMP health check endpoints to register.

    WHY THIS MATTERS — this drives count, not for_each.
    These are positional/identical — no natural key exists.
    Count is appropriate here. for_each would require inventing keys.
  EOT
  type    = number
  default = 2

  validation {
    condition     = var.icmp_check_count >= 0 && var.icmp_check_count <= 10
    error_message = "icmp_check_count must be between 0 and 10."
  }
}
