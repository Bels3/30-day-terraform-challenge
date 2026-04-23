# VaultEdge · environments/dev/main.tf
# This is the ROOT MODULE for the dev environment.
# It calls two child modules and wires their outputs together.

# WHY THIS MATTERS — root module vs child module
# Every terraform init/plan/apply is run FROM a root module directory.
# Child modules are called FROM the root module using module blocks.
# The root module is what you're in when you run terraform commands.

terraform {
  # WHY THIS MATTERS — required_version in the TERRAFORM block, not provider block.
  # This is a common exam trap. required_version belongs here, in terraform {}.
  # If the running Terraform binary doesn't satisfy this constraint,
  # Terraform exits with an error before doing ANYTHING else.
  required_version = ">= 1.5.0"

  required_providers {
    # WHY THIS MATTERS — reading these constraints deliberately:
    
    # random = "~> 3.0"
    # Two components → allows >= 3.0.0 and < 4.0.0
    # We want any stable random 3.x. We don't need to lock to a minor series.
    
    # local = "~> 2.4"
    # Two components → allows >= 2.4.0 and < 3.0.0
    # We know local 2.x is stable. Minor increments are safe. We accept them.
    
    # CONTRAST: if we wrote local = "~> 2.4.0" (three components)
    # that would mean >= 2.4.0 and < 2.5.0 — patches only.
    # That's more restrictive. Use three components when a minor bump
    # could introduce breaking changes you're not ready to absorb.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

  # WHY THIS MATTERS — backend configuration
  # Dev uses local backend (default). State is stored in terraform.tfstate
  # in this directory. This is fine for solo dev work but NOT for teams.
  # In prod (see environments/prod/backend.tf) we show what a remote
  # backend configuration looks like, even though we use local for this project.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# MODULE: NETWORK

# WHY THIS MATTERS — calling a local module
# source = "./path" for local modules. No version argument — local modules
# have no versioning. You get whatever is on disk at that path.

# EXAM RULE: version argument is ONLY valid for registry sources.
# Local paths → no version
# Git sources → use ?ref= in the URL
# Terraform Registry → use version = "x.y.z"
module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment

  subnets = [
    { name = "public",     cidr = "10.0.1.0/24", public = true  },
    { name = "private",    cidr = "10.0.2.0/24", public = false },
    { name = "management", cidr = "10.0.3.0/24", public = false }
  ]

  # Dev has minimal firewall rules — 3 rules
  firewall_rules = [
    { description = "Allow HTTPS inbound",  port = 443, protocol = "tcp", direction = "inbound",  allow = true  },
    { description = "Allow HTTP inbound",   port = 80,  protocol = "tcp", direction = "inbound",  allow = true  },
    { description = "Allow SSH management", port = 22,  protocol = "tcp", direction = "inbound",  allow = true  }
  ]

  icmp_check_count = 2
}

# MODULE: APP

# WHY THIS MATTERS — wiring module outputs to module inputs
# module.network.network_id reads the network_id output from the network module.
# This is how child modules communicate — through the root module.
# Child modules cannot directly reference each other's values.
module "app" {
  source = "../../modules/app"

  project_name = var.project_name
  environment  = var.environment
  network_id   = module.network.network_id  # output from network module → input to app module

  services = [
    { name = "gateway",  port = 8080, replicas = 1 },
    { name = "auth",     port = 8081, replicas = 1 },
    { name = "payments", port = 8082, replicas = 1 }
  ]
}

# SUMMARY FILE — root module writing its own resource
# Documents what was deployed, combining outputs from both modules.
resource "local_file" "deployment_summary" {
  filename = ".generated/deployment-summary.json"
  content = jsonencode({
    project         = var.project_name
    environment     = var.environment
    network_id      = module.network.network_id
    subnet_ids      = module.network.subnet_ids
    firewall_count  = module.network.firewall_rule_count
    service_ids     = module.app.service_ids
    service_labels  = module.app.service_labels
    config_path     = module.app.config_path
    manifest_path   = module.app.deploy_manifest_path
  })
  file_permission = "0644"

  # WHY THIS MATTERS — explicit depends_on at root module level
  # Both modules must fully complete before we write the summary.
  # Without depends_on, Terraform might try to write this file before
  # module outputs are fully resolved, since there is no direct attribute
  # reference that establishes the full ordering.
  depends_on = [module.network, module.app]
}
