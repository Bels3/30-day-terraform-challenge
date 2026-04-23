# VaultEdge · environments/prod/variables.tf

variable "project_name" {
  description = "Project name prefix."
  type        = string
  default     = "vaultedge"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}
