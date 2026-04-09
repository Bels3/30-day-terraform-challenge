# day22/webserver-cluster/locals.tf
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.owner
    Day         = "22"
  }
}
