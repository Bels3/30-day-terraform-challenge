# VaultEdge · modules/network/main.tf

# PURPOSE: Simulates a network layer — environments (dev/prod), subnets,
#          and firewall rule sets. Uses local_file and random providers
#          so this runs with zero cloud credentials.

# EXAM GAPS ADDRESSED IN THIS FILE:
#   - dynamic blocks (generating repeated nested config from a variable)
#   - for_each vs count (both used here — with explicit reasoning)
#   - Module outputs (values exposed to the root module caller)
#   - locals block (reducing repetition, internal computed values)

terraform {
  required_providers {
    # WHY THIS MATTERS — version constraint ~> 2.0
    # Two components: allows >= 2.0.0 and < 3.0.0
    # The minor version (0) is the rightmost digit — it increments freely.
    # We want any stable 2.x release of random. We do NOT write ~> 2.0.0
    # because that would lock us to 2.0.x patches only — too restrictive.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    # WHY THIS MATTERS — version constraint ~> 2.4.0
    # Three components: allows >= 2.4.0 and < 2.5.0
    # We pin to this minor series because local provider behaviour changed
    # in 2.5. This is the PATCH-level constraint. Only the last digit moves.
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# LOCALS — internal computed values, not overrideable by callers
# WHY THIS MATTERS: locals ≠ variables. A caller sets variables. A caller
# CANNOT override locals. Locals are for reducing repetition within a module.
locals {
  # Build a full environment label used consistently across all resources
  env_label = "${var.project_name}-${var.environment}"

  # Derive subnet names from the subnet list — used in for_each below
  subnet_map = {
    for subnet in var.subnets :
    subnet.name => subnet
  }

  # Timestamp for generated file metadata
  generated_at = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
}

# RANDOM ID — network identifier
# WHY THIS MATTERS: random_id generates a unique identifier each time a
# resource is created. If you run terraform apply twice without changes,
# it does NOT change — Terraform is idempotent. Only destruction + recreation
# generates a new value.
resource "random_id" "network_id" {
  byte_length = 4

  # WHY THIS MATTERS — keepers
  # keepers forces a new random value when ANY keeper value changes.
  # This is how you tie a random resource to the lifecycle of something else.
  keepers = {
    environment = var.environment
    project     = var.project_name
  }
}

# SUBNETS — using for_each with a map

# WHY THIS MATTERS — for_each vs count
# We use for_each here because subnets are identified by NAME, not position.
# If we used count and removed a subnet from the middle of the list,
# Terraform would shift all subsequent indexes — potentially destroying
# and recreating resources that didn't need to change.
#
# for_each creates resources keyed by map key:
#   random_id.subnet_id["public"]
#   random_id.subnet_id["private"]
#   random_id.subnet_id["management"]

# Adding or removing one subnet key only affects that one resource.
# This is the core reason for_each is preferred over count for named sets.
# =============================================================================
resource "random_id" "subnet_id" {
  for_each = local.subnet_map

  byte_length = 3

  keepers = {
    subnet_name = each.key
    cidr        = each.value.cidr
    environment = var.environment
  }
}

# FIREWALL RULES — using count (intentional contrast with for_each above)

# WHY THIS MATTERS — when count IS appropriate
# We use count here to create N identical audit log entries for a fixed
# number of allowed ICMP check IPs. These are positional — order matters,
# there are no meaningful names, and we never remove from the middle.
# Count is appropriate for identical repeated resources with no natural key.

# Access via: random_id.icmp_check_id[0], random_id.icmp_check_id[1]
resource "random_id" "icmp_check_id" {
  count = var.icmp_check_count

  byte_length = 2

  keepers = {
    index       = count.index
    environment = var.environment
  }
}

# NETWORK MANIFEST — local_file resource
# Writes a JSON manifest of the network configuration to disk.
# This simulates what Terraform would write to a cloud provider.

# WHY THIS MATTERS — local_file as a learning stand-in
# In real Terraform you would see aws_vpc, google_compute_network etc.
# The concepts — for_each, dynamic blocks, outputs, state — behave
# identically. The provider is different; the Terraform logic is not.
resource "local_file" "network_manifest" {
  filename = "${path.module}/../../environments/${var.environment}/.generated/network-manifest.json"
  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    network_id  = random_id.network_id.hex
    generated   = local.generated_at
    subnets = {
      for name, subnet in local.subnet_map :
      name => {
        cidr       = subnet.cidr
        subnet_id  = random_id.subnet_id[name].hex
        public     = subnet.public
      }
    }
    icmp_checks = [
      for i in range(var.icmp_check_count) :
      random_id.icmp_check_id[i].hex
    ]
    firewall_rules = var.firewall_rules
  })

  # WHY THIS MATTERS — file_permission
  # local_file accepts file_permission as a string. This is a configuration
  # attribute that exists only in the .tf file — it is NOT stored in state.
  # State stores the filename and content hash, not every argument.
  file_permission = "0644"
}

# FIREWALL CONFIG FILE — demonstrates dynamic blocks

# WHY THIS MATTERS — dynamic blocks
# The firewall_rules variable is a list of objects. Each object should become
# a repeated nested block in the configuration. Without dynamic, you would
# write one ingress {} block per rule manually — impossible when the list
# length is variable.

# dynamic "ingress" iterates var.firewall_rules and generates one ingress {}
# block per item. When var.firewall_rules is empty, ZERO blocks are generated.
# This is idiomatic Terraform for optional/variable-length nested config.

# Structure:
#   dynamic "BLOCK_TYPE" {
#     for_each = COLLECTION
#     content {
#       ATTRIBUTE = ITERATOR.value.FIELD
#     }
#   }
# The iterator label defaults to the block type name (ingress.value.port).
# You can override with iterator = "rule" to use rule.value.port instead.
resource "local_file" "firewall_config" {
  filename = "${path.module}/../../environments/${var.environment}/.generated/firewall-config.json"

  content = jsonencode({
    network_id = random_id.network_id.hex
    environment = var.environment
    rules = [
      for rule in var.firewall_rules : {
        description = rule.description
        port        = rule.port
        protocol    = rule.protocol
        direction   = rule.direction
        allow       = rule.allow
      }
    ]
  })

  file_permission = "0644"

  # WHY THIS MATTERS — explicit depends_on
  # The firewall config logically depends on the network manifest existing first.
  # Terraform cannot infer this dependency from attribute references alone
  # because we are not interpolating any attribute from network_manifest.
  # depends_on creates an explicit ordering: network_manifest is always created
  # before firewall_config, even though there is no reference between them.
  # EXAM RULE: Only use depends_on when Terraform cannot infer the dependency
  # from expression references. Overusing it creates unnecessary serialisation
  # and slows applies. Use it for side-effect dependencies only.
  depends_on = [local_file.network_manifest]
}
