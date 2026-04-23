# Runbook 02 — Version Constraints
## VaultEdge · Day 29 Practical Project

This concept appeared in wrong answers across MULTIPLE exams. This runbook
closes it permanently with the rule, every operator, and active exercises.

---

## The One Rule That Explains Everything

The pessimistic constraint operator `~>` allows **only the rightmost specified
version component to increment freely**.

Count the components. That tells you everything.

```
~> 1.0      → TWO components   → rightmost is MINOR  → >= 1.0.0, < 2.0.0
~> 1.0.0    → THREE components → rightmost is PATCH  → >= 1.0.0, < 1.1.0
~> 2.4      → TWO components   → rightmost is MINOR  → >= 2.4.0, < 3.0.0
~> 2.4.0    → THREE components → rightmost is PATCH  → >= 2.4.0, < 2.5.0
~> 3.5      → TWO components   → rightmost is MINOR  → >= 3.5.0, < 4.0.0
~> 3.5.2    → THREE components → rightmost is PATCH  → >= 3.5.2, < 3.6.0
```

This is exactly the distinction between `dev` and `prod` in this project:
- Dev `local = "~> 2.4"` → accepts 2.4, 2.5, 2.6... up to (not including) 3.0
- Prod `local = "~> 2.4.0"` → accepts 2.4.0, 2.4.1, 2.4.9 — nothing above 2.4.x

---

## All Constraint Operators

| Operator | Name | Meaning | Example | Allows |
|---|---|---|---|---|
| `=` | Exact | Exactly this version | `= 2.4.0` | Only 2.4.0 |
| `!=` | Not equal | Any version except this | `!= 2.4.0` | Everything except 2.4.0 |
| `>` | Greater than | Strictly above | `> 2.4.0` | 2.4.1, 2.5.0, 3.0.0... |
| `>=` | Greater than or equal | This version and above | `>= 2.4.0` | 2.4.0, 2.4.1, 3.0.0... |
| `<` | Less than | Strictly below | `< 3.0.0` | 2.9.9, 2.0.0... |
| `<=` | Less than or equal | This version and below | `<= 2.4.0` | 2.4.0, 2.3.9... |
| `~>` | Pessimistic | Count the components | `~> 2.4` | >= 2.4.0, < 3.0.0 |

---

## Combining Operators

Multiple constraints on the same provider are AND conditions — ALL must be true.

```hcl
# Both conditions must be satisfied:
version = ">= 2.4.0, < 3.0.0"   # equivalent to ~> 2.4

# More explicit range:
version = ">= 1.5.0, < 2.0.0, != 1.6.0"  # any 1.x above 1.5 except 1.6.0
```

---

## Where Version Constraints Live in This Project

Open `environments/dev/main.tf` and `environments/prod/main.tf` side by side.
Find the `required_providers` blocks.

Dev:
```hcl
random = { source = "hashicorp/random", version = "~> 3.0"   }
local  = { source = "hashicorp/local",  version = "~> 2.4"   }
```

Prod:
```hcl
random = { source = "hashicorp/random", version = "~> 3.5"   }
local  = { source = "hashicorp/local",  version = "~> 2.4.0" }
```

**Ask yourself for each one:** What is the floor version? What is the ceiling?
Write your answers before checking against the table above.

---

## Module Version Constraints — The Other Exam Gap

Open `environments/dev/main.tf`. Find the two module blocks.

```hcl
module "network" {
  source = "../../modules/network"
  # No version argument — WHY?
}
```

**Rule:** The `version` argument in a module block only works with Terraform
Registry sources. It does NOT work with local paths or Git sources.

| Source type | Version argument | Alternative pinning |
|---|---|---|
| Registry `hashicorp/consul/aws` | `version = "~> 0.1"` ✅ | N/A |
| Local path `./modules/vpc` | ❌ Not supported | Use git tag on the repo |
| GitHub `github.com/org/repo` | ❌ Not supported | Use `?ref=v1.0.0` in URL |
| Git URL `git::https://...` | ❌ Not supported | Use `?ref=tagname` |

**What your exam Q40 tested:** "Which module source requires a version argument?"
Answer: Terraform Registry. GitHub → use `?ref=`. Local paths → no versioning at all.

---

## Active Exercises

### Exercise 1 — Break a constraint deliberately

In `environments/dev/main.tf`, temporarily change:
```hcl
version = "~> 3.0"
```
to:
```hcl
version = "= 99.0.0"
```

Run:
```bash
terraform init
```

You will see an error: no available version satisfying the constraint.
This is exactly what happens in production when a constraint is too strict
and a required version doesn't exist.

**Restore** the original constraint before continuing.

---

### Exercise 2 — Read the lock file

After `terraform init` runs successfully, open `.terraform.lock.hcl`:

```bash
cat .terraform.lock.hcl
```

You will see something like:
```hcl
provider "registry.terraform.io/hashicorp/local" {
  version     = "2.4.0"
  constraints = "~> 2.4"
  hashes = [
    "h1:...",
  ]
}
```

**What to notice:**
- `version` = exact version Terraform selected (within the constraint)
- `constraints` = the constraint string from your config
- `hashes` = cryptographic checksums for integrity verification

**Exam rule:** The lock file records the EXACT version selected, not just the constraint.
Committing it ensures all team members use the identical provider version.
`terraform init -upgrade` ignores the lock file and re-resolves to newest matching version.

---

### Exercise 3 — Write the constraints from memory

Without looking at the table, write the version range for each:

1. `~> 4.2.1`  → ____________________
2. `~> 0.13`   → ____________________
3. `>= 1.0, < 2.0.0` → ____________________
4. `~> 1.0.0`  → ____________________
5. `!= 3.0.0`  → ____________________

**Answers:**
1. `>= 4.2.1, < 4.3.0`
2. `>= 0.13.0, < 1.0.0`
3. `>= 1.0.0, < 2.0.0` (same as `~> 1.0`)
4. `>= 1.0.0, < 1.1.0`
5. Any version except exactly 3.0.0
