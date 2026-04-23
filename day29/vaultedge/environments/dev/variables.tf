# VaultEdge · environments/dev/variables.tf

variable "project_name" {
  description = "Project name. Used as a prefix across all resources."
  type        = string
  default     = "vaultedge"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}
