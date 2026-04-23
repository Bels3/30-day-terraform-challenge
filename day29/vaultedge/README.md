# VaultEdge Infrastructure — Day 29 Practical Project

## What This Is

VaultEdge is a fictional fintech API that needs two isolated environments — **dev** and **prod** —
provisioned from a single shared codebase. No AWS credentials required. This project runs entirely
on the `local` and `random` providers, which means zero cost, zero free-tier depletion, and full
focus on the Terraform concepts that showed up as gaps across four practice exams.

Every concept here appears because the **problem requires it**.

## Project Structure

```
vaultedge/
├── README.md                        ← you are here
├── modules/
│   ├── network/                     ← reusable network module (gap: module sources, outputs, version)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── app/                         ← reusable app config module (gap: dynamic blocks, for_each vs count)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/                         ← dev environment root module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/                        ← prod environment root module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── runbooks/
    ├── 01-state-operations.md       ← gap: state pull, state rm, state mv, import
    ├── 02-version-constraints.md    ← gap: ~> 1.0 vs ~> 1.0.0, all operators
    └── 03-terraform-cloud.md        ← gap: run modes, Sentinel, no-code provisioning
```

## Gaps This Project Addresses

| Exam Gap | Where It Appears | What You Will Do |
|---|---|---|
| `~> 1.0` vs `~> 1.0.0` | `environments/*/main.tf` required_providers | Set constraints deliberately, explain why |
| Module version argument rules | `modules/network` and `modules/app` calls | Understand why local modules don't use version |
| `terraform state pull` vs refresh | `runbooks/01-state-operations.md` | Run the command, inspect the output |
| Dynamic blocks | `modules/app/main.tf` | Generate repeated config blocks from a variable list |
| `for_each` vs `count` | `modules/app/main.tf` | Two resources — one each, with annotated reasoning |
| Module outputs | `modules/network/outputs.tf` | Expose values, consume them in root module |
| `prevent_destroy` lifecycle | `environments/prod/main.tf` | Apply it, then try to destroy and read the error |
| Terraform Cloud run modes | `runbooks/03-terraform-cloud.md` | CLI-driven live config + VCS/API-driven explained |
| `depends_on` explicit dependency | `environments/dev/main.tf` | Use it where reference alone is not enough |
| `sensitive` output values | `modules/app/outputs.tf` | Mark a value sensitive, observe redaction |

---

## How to Run This

### Prerequisites
```bash
terraform version   # needs >= 1.5.0
```
No cloud credentials needed. The `local` and `random` providers work offline.

### Run dev environment
```bash
cd environments/dev
terraform init
terraform plan
terraform apply -auto-approve
```

### Run prod environment
```bash
cd environments/prod
terraform init
terraform plan
terraform apply -auto-approve
```

### After apply — run the runbooks in order
1. `runbooks/01-state-operations.md` — state commands hands-on
2. `runbooks/02-version-constraints.md` — constraint operator reference + exercises
3. `runbooks/03-terraform-cloud.md` — Terraform Cloud concepts grounded in this project

---

## The Learning Contract

Each file in this project has a `# WHY THIS MATTERS` comment block.
Do not skip them. They are the annotations that connect the code to the exam gap.
The code works without reading them. The learning does not.
