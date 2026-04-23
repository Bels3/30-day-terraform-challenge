# VaultEdge · modules/app/main.tf

# PURPOSE: Simulates application configuration — API service identifiers,
#          environment config files, and deployment manifests.
#
# EXAM GAPS ADDRESSED IN THIS FILE:
#   - lifecycle rules: prevent_destroy, create_before_destroy, ignore_changes
#   - sensitive output values
#   - for expression transforming a collection
#   - description argument NOT stored in state (verified in runbook)

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

locals {
  service_prefix = "${var.project_name}-${var.environment}-api"

  # WHY THIS MATTERS — for expression producing a map
  # This transforms a list of service names into a map of name → config.
  # for expressions are used within expressions to reshape data.
  # They do NOT create resources — use for_each on a resource for that.
  
  # Syntax: { for item in collection : key => value }
  service_config = {
    for svc in var.services :
    svc.name => {
      port     = svc.port
      replicas = svc.replicas
      label    = "${local.service_prefix}-${svc.name}"
    }
  }
}

# API KEY — sensitive random value
#
# WHY THIS MATTERS — random_password for sensitive values
# random_password generates a value that Terraform automatically marks as
# sensitive in plan and apply output. It will show as (sensitive value)
# in the CLI — but it IS stored in plain text in the state file.
# "Sensitive" in Terraform means "don't display it" not "encrypt it in state".
resource "random_password" "api_key" {
  length  = 32
  special = false

  # WHY THIS MATTERS — keepers tie this random value to environment lifecycle.
  # If environment changes, a new API key is generated. If nothing changes,
  # the same key persists across applies — Terraform is idempotent.
  keepers = {
    environment = var.environment
    project     = var.project_name
  }
}

# SERVICE IDs — for_each over the services map
# Each service gets its own identifier, keyed by service name.
resource "random_id" "service_id" {
  for_each = local.service_config

  byte_length = 4

  keepers = {
    service = each.key
    env     = var.environment
  }
}

# ENVIRONMENT CONFIG FILE

# WHY THIS MATTERS — prevent_destroy lifecycle
# In production, the environment config file must never be accidentally
# destroyed. prevent_destroy = true causes Terraform to ERROR if any plan
# would destroy this resource.
#
# CRITICAL EXAM DISTINCTION:
#   prevent_destroy = true → Terraform errors on a plan that would destroy it
#   It does NOT prevent: terraform state rm (state-only removal)
#   It does NOT prevent: manual deletion of the file from the filesystem
#   It does NOT prevent: the cloud console deleting a cloud resource
# prevent_destroy only blocks Terraform-initiated destroys via a plan.

resource "local_file" "env_config" {
  filename = "${path.module}/../../environments/${var.environment}/.generated/app-config.json"

  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    api_key_ref = "REDACTED_SEE_STATE"  # never write actual secrets to config files
    services = {
      for name, config in local.service_config :
      name => {
        id       = random_id.service_id[name].hex
        port     = config.port
        replicas = config.replicas
        label    = config.label
      }
    }
  })

  file_permission = "0600"

  lifecycle {
    prevent_destroy = true

    # WHY THIS MATTERS — ignore_changes
    # file_permission might be modified by another process or operator.
    # We tell Terraform to ignore drift on file_permission — if it changes
    # outside Terraform, Terraform will not plan a correction.
    
    # EXAM RULE: ignore_changes accepts a LIST of attribute names, not booleans.
    # ignore_changes = all is valid and ignores ALL attribute changes.
    # ignore_changes = [content] means only content changes are ignored.
    ignore_changes = [file_permission]
  }
}

# DEPLOYMENT MANIFEST — create_before_destroy lifecycle

# WHY THIS MATTERS — create_before_destroy
# When Terraform needs to replace this file (because content changes force
# a new resource), the DEFAULT behaviour is:
#   1. Destroy the old file
#   2. Create the new file
#
# With create_before_destroy = true the sequence becomes:
#   1. Create the new file
#   2. Destroy the old file
#
# For local_file this doesn't matter much. In production — for load balancer
# target groups, DNS records, or SSL certificates — the ordering prevents
# downtime during replacement.

resource "local_file" "deploy_manifest" {
  filename = "${path.module}/../../environments/${var.environment}/.generated/deploy-manifest.json"

  content = jsonencode({
    project      = var.project_name
    environment  = var.environment
    network_id   = var.network_id
    deployed_at  = timestamp()
    service_ids = {
      for name, sid in random_id.service_id :
      name => sid.hex
    }
  })

  file_permission = "0644"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [local_file.env_config]
}
