# Runbook 03 — Terraform Cloud Concepts
## VaultEdge · Day 29 Practical Project

You cannot run Terraform Cloud locally — but you CAN understand every concept
deeply by connecting them to what you just built. This runbook maps each TFC
feature to the VaultEdge project so the concepts are grounded, not floating.

---

## The Three Run Modes — Grounded in VaultEdge

Right now you run VaultEdge like this:
```bash
cd environments/dev
terraform init
terraform apply
```

That is **CLI-driven** — you are triggering the run from your local terminal.
The plan and apply execute on your machine.

In Terraform Cloud, the same three steps happen but WHERE they execute changes
based on the run mode.

---

### Mode 1: CLI-Driven

**What it is:** You run `terraform apply` from your local terminal. Terraform
Cloud intercepts the operation and executes it remotely in TFC's infrastructure.
You see the output streaming back to your terminal as if it were local.

**How you configure it (in this project):**
If you connected this project to TFC, you'd add to `backend.tf`:

```hcl
terraform {
  cloud {
    organization = "vaultedge-org"
    workspaces {
      name = "vaultedge-dev"
    }
  }
}
```

Then `terraform apply` from your terminal sends the run to TFC.
Your local terminal is the trigger. TFC is the executor.

**When to use it:** Developer workflows. You want the power of TFC (remote state,
run history, team visibility) but you want to trigger runs manually from CLI.

---

### Mode 2: VCS-Driven

**What it is:** Terraform Cloud watches a connected Git repository.
When you push a commit or merge a pull request to the configured branch,
TFC automatically queues a plan (and optionally auto-applies).

**How this maps to VaultEdge:**
Imagine you push a change to `environments/dev/main.tf` adding a new service.
TFC detects the commit, runs `terraform plan`, posts the plan as a PR check,
and waits for approval before applying.

**The flow:**
```
git push origin main
       ↓
TFC webhook fires
       ↓
TFC runs terraform plan
       ↓
Plan output posted to PR / Slack
       ↓
Team approves
       ↓
TFC runs terraform apply
```

**When to use it:** GitOps workflows. Infrastructure changes flow through
pull requests. No one runs `terraform apply` from their laptop in prod.

---

### Mode 3: API-Driven

**What it is:** A CI/CD pipeline (GitHub Actions, Jenkins, CircleCI) makes
explicit API calls to the Terraform Cloud API to trigger runs.

**How this maps to VaultEdge:**
Your GitHub Actions workflow runs tests, then calls the TFC API to trigger
a `terraform apply` for the relevant environment. The pipeline controls WHEN
runs happen — not a git push, not a CLI command.

```yaml
# GitHub Actions example (conceptual)
- name: Deploy to dev
  run: |
    curl -X POST \
      -H "Authorization: Bearer $TFC_TOKEN" \
      -d '{"data":{"type":"runs","relationships":{"workspace":{"data":{"id":"ws-xxx"}}}}}' \
      https://app.terraform.io/api/v2/runs
```

**When to use it:** Complex pipelines where you need conditional logic before
deploying. "Run tests first, deploy only if tests pass, notify Slack either way."
The pipeline owns the orchestration; TFC owns the execution.

---

## Quick-Fire Distinction Test

| Scenario | Run mode |
|---|---|
| Developer types `terraform apply` from laptop, TFC executes it | CLI-driven |
| Merging a PR to main triggers a plan in TFC | VCS-driven |
| GitHub Actions calls the TFC API after tests pass | API-driven |
| Jenkins polls TFC and triggers a run on schedule | API-driven |
| You run `terraform plan` and output streams to your terminal via TFC | CLI-driven |

---

## Sentinel — Policy as Code

**What it is:** A framework that enforces rules AFTER plan and BEFORE apply.
Think of it as a compliance gate: "Before we apply anything, check that it
meets our organisation's rules."

**How this maps to VaultEdge:**
Imagine a Sentinel policy: "All VaultEdge prod resources must have prevent_destroy = true."
Before any prod apply, Sentinel checks this. If the policy fails, the run stops.

**Three enforcement levels — you must know all three:**

```
Advisory          → Logs a warning. Apply proceeds anyway.
                   "Hey, this resource has no tags. Just so you know."

Soft-Mandatory    → Blocks the run. An authorised user can OVERRIDE and proceed.
                   "This violates our tagging policy. Override if you have a reason."

Hard-Mandatory    → Blocks the run. NO override possible. Cannot proceed.
                   "This would deploy to prod without a change request. Full stop."
```

**Exam trap:** "Which enforcement level cannot be overridden?"
Answer: Hard-mandatory. Soft-mandatory CAN be overridden by authorised users.

---

## No-Code Provisioning

**What it is:** An admin publishes a Terraform module to the private registry
and marks it as available for no-code provisioning. Non-technical users see
a form with fields (variable inputs). They fill in values and click Deploy.
No Terraform code is written by the end user.

**How this maps to VaultEdge:**
You publish the `modules/network` module to your org's private registry.
A developer who needs a dev network goes to the TFC UI, sees a form:
- Project name: [text field]
- Environment: [dropdown: dev / staging / prod]
- Subnets: [multi-select]

They fill it in, click Deploy. TFC runs `terraform apply` with those variable
values. The developer never sees a `.tf` file.

**Who controls what:**
- Admin: writes the module, publishes it, sets which variables are exposed
- User: fills in variable values through the UI, triggers the deploy
- TFC: executes the apply with the module code and user-provided values

---

## Agent Pools (The Distractor You Chose in Exam 3)

**What it is:** Self-hosted compute that executes TFC runs inside your private network.

**Why it exists:** TFC's shared infrastructure cannot reach private networks
(on-premises data centres, private VPCs without public internet access).
Agent pools are your own servers registered with TFC that TFC can delegate
runs to. The run executes ON YOUR INFRASTRUCTURE, not on TFC's shared runners.

**The exam distinction:**
- Agent pools → WHERE runs execute (private network runners)
- No-code provisioning → WHO can trigger runs (non-technical users via form UI)

They are completely different features. No-code provisioning uses whatever
run infrastructure is configured for the workspace — it could use agent pools.
But the FEATURE that enables non-technical users to deploy without writing code
is no-code provisioning, not agent pools.

---

## Terraform Cloud Workspaces vs CLI Workspaces

This is one of the sharpest distinctions on the exam.

| | CLI Workspaces | TFC Workspaces |
|---|---|---|
| Created with | `terraform workspace new` | TFC UI / API |
| What's isolated | State file only | State + variables + runs + access controls + history |
| Same config? | Yes — one config, multiple state files | No — typically one config per workspace |
| Practical use | Simple environment separation | Full environment isolation in teams |
| Delete default? | No — default workspace cannot be deleted | N/A |

**The mental model:**
CLI workspace = same house, different rooms (same config, different state files).
TFC workspace = different houses entirely (different state, different settings, different access).

---

## Private Module Registry

**What it is:** A registry within your Terraform Cloud organisation for sharing
internal modules. Same interface as the public registry — versioned releases,
documentation, input/output schemas — but private to your org.

**How this maps to VaultEdge:**
Publishing `modules/network` to your private registry means:
- Any team in the org can use it: `source = "app.terraform.io/vaultedge-org/network/local"`
- The `version` argument works (unlike local paths)
- You can pin: `version = "~> 1.2"`
- Other teams can browse it in the TFC UI with auto-generated docs

**Exam rule:** Private registry modules DO support the `version` argument.
Local path modules do NOT. This is where module source + versioning intersects
with Terraform Cloud.
