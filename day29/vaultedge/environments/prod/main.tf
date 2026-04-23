# VaultEdge · environments/prod/main.tf

# PURPOSE: Production environment. Same modules as dev — different variable
#          values, stricter version constraints, and lifecycle protections
#          that would be dangerous in dev but are required in prod.
#
# EXAM GAPS ADDRESSED IN THIS FILE vs dev/main.tf:
#   - Stricter version constraints (three-component ~> x.y.z)
#   - prevent_destroy on the summary file (prod must not be accidentally wiped)
#   - More firewall rules → more dynamic block iterations
#   - Higher replica counts → demonstrates modules are environment-agnostic


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # WHY THIS MATTERS — prod uses STRICTER version constraints than dev.
   
    # Dev uses: random = "~> 3.0"   → accepts 3.0.x through 3.999.x
    # Prod uses: random = "~> 3.5"  → accepts 3.5.x through 3.999.x
    # Still two components but the floor is higher — we know 3.5+ is stable.
    
    # Dev uses: local = "~> 2.4"    → accepts 2.4.x through 2.999.x
    # Prod uses: local = "~> 2.4.0" → accepts ONLY 2.4.x patches
    # THREE components in prod. We have tested 2.4.x in prod. We do not
    # want a 2.5 minor release automatically pulled in prod without review.
    # Minor releases CAN introduce behaviour changes. Prod takes no chances.
    
    # THIS IS THE CORE ~> 1.0 vs ~> 1.0.0 EXAM CONCEPT IN REAL CONTEXT:
    # dev  → ~> 2.4   = >= 2.4.0, < 3.0.0  (accept any stable 2.x above 2.4)
    # prod → ~> 2.4.0 = >= 2.4.0, < 2.5.0  (accept only 2.4.x patches)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }

  # WHY THIS MATTERS — remote backend (shown as local for this project)
  # In a real prod environment this would be:
  
  #   backend "s3" {
  #     bucket         = "vaultedge-terraform-state"
  #     key            = "prod/terraform.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "vaultedge-state-lock"   ← pre-1.10 locking
  #     encrypt        = true
  #   }
  
  # As of Terraform 1.10+, native S3 locking via conditional writes is
  # available (use_lockfile = true) — DynamoDB is no longer required.
  # The EXAM still tests the S3 + DynamoDB pattern as the canonical answer
  # because exam objectives reflect pre-1.10 behaviour.
  #
  # For this local project we use local backend but the comment above
  # documents exactly what a real prod remote backend looks like.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# MODULE: NETWORK (prod)
# Same module, different inputs. This is the power of reusable modules.
# The module code is identical — the environment-specific values differ.
module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment

  subnets = [
    { name = "public",     cidr = "10.1.1.0/24", public = true  },
    { name = "private",    cidr = "10.1.2.0/24", public = false },
    { name = "management", cidr = "10.1.3.0/24", public = false },
    { name = "data",       cidr = "10.1.4.0/24", public = false }
  ]

  # Prod has more firewall rules — dynamic block generates 6 entries vs dev's 3.
  # The module code is unchanged. The dynamic block adapts to the input.
  # This is exactly why dynamic blocks exist — variable-length nested config.
  firewall_rules = [
    { description = "Allow HTTPS inbound",    port = 443,  protocol = "tcp", direction = "inbound",  allow = true  },
    { description = "Allow HTTP redirect",    port = 80,   protocol = "tcp", direction = "inbound",  allow = true  },
    { description = "Deny SSH from internet", port = 22,   protocol = "tcp", direction = "inbound",  allow = false },
    { description = "Allow bastion SSH",      port = 22,   protocol = "tcp", direction = "internal", allow = true  },
    { description = "Allow metrics scrape",   port = 9090, protocol = "tcp", direction = "internal", allow = true  },
    { description = "Allow health checks",    port = 8080, protocol = "tcp", direction = "internal", allow = true  }
  ]

  icmp_check_count = 3
}

# MODULE: APP (prod)
# Higher replica counts, more services — same module, different variable values.
module "app" {
  source = "../../modules/app"

  project_name = var.project_name
  environment  = var.environment
  network_id   = module.network.network_id

  services = [
    { name = "gateway",  port = 8080, replicas = 3 },
    { name = "auth",     port = 8081, replicas = 2 },
    { name = "payments", port = 8082, replicas = 3 },
    { name = "ledger",   port = 8083, replicas = 2 },
    { name = "audit",    port = 8084, replicas = 2 }
  ]
}

# PROD SUMMARY FILE — with prevent_destroy

# WHY THIS MATTERS — prevent_destroy at the ROOT MODULE level
# In dev, we let the summary file be destroyed freely.
# In prod, destroying the deployment summary is a signal something has gone
# wrong. We want Terraform to STOP and make a human confirm explicitly.
#
# To destroy prod (legitimate decommission), you must:
#   1. Remove prevent_destroy = true from this lifecycle block
#   2. Run terraform apply (to update state with the changed lifecycle)
#   3. Run terraform destroy
#
# This is intentional friction. Production teardown should require intent.
resource "local_file" "deployment_summary" {
  filename = ".generated/deployment-summary.json"
  content = jsonencode({
    project        = var.project_name
    environment    = var.environment
    network_id     = module.network.network_id
    subnet_ids     = module.network.subnet_ids
    firewall_count = module.network.firewall_rule_count
    service_ids    = module.app.service_ids
    service_labels = module.app.service_labels
  })
  file_permission = "0644"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [module.network, module.app]
}
