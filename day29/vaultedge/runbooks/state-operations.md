# Runbook 01 — State Operations
## VaultEdge · Day 29 Practical Project

Run this AFTER `terraform apply` has succeeded in both `environments/dev` and `environments/prod`.

---

## The Core Mental Model

Terraform state is a **mapping** between your configuration and real-world resources.
It answers one question: *what does Terraform currently manage, and what are the real IDs?*

Every state command operates on this mapping. Understanding what each command does
**to the mapping** vs **to the real infrastructure** is where most exam mistakes live.

```
┌─────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  .tf config     │  plan   │   state file      │  apply  │  real infra      │
│  (desired)      │ ──────► │   (known state)   │ ──────► │  (actual)        │
└─────────────────┘         └──────────────────┘         └──────────────────┘
```

State commands operate on the MIDDLE box only — unless you run apply/destroy,
the RIGHT box (real infra) is never touched.

---

## Exercise 1 — terraform state list

```bash
cd environments/dev

terraform state list
```

Expected output — something like:
```
local_file.deployment_summary
module.app.local_file.deploy_manifest
module.app.local_file.env_config
module.app.random_id.service_id["auth"]
module.app.random_id.service_id["gateway"]
module.app.random_id.service_id["payments"]
module.app.random_password.api_key
module.network.local_file.firewall_config
module.network.local_file.network_manifest
module.network.random_id.icmp_check_id[0]
module.network.random_id.icmp_check_id[1]
module.network.random_id.network_id
module.network.random_id.subnet_id["management"]
module.network.random_id.subnet_id["private"]
module.network.random_id.subnet_id["public"]
```

**What you are seeing:** Every resource address in state. Notice:
- `module.app.random_id.service_id["auth"]` — for_each resource, keyed by string
- `module.network.random_id.icmp_check_id[0]` — count resource, keyed by integer
- `local_file.deployment_summary` — root module resource (no module prefix)

**Exam insight:** Resource addresses tell you instantly whether count or for_each was used.
`["string"]` = for_each. `[integer]` = count.

---

## Exercise 2 — terraform state show

```bash
terraform state show module.network.random_id.network_id
```

This prints every attribute Terraform knows about this resource.

```bash
terraform state show module.app.random_password.api_key
```

**What you will see:** `result = (sensitive value)` — the sensitive flag is respected
in state show output too. But the value IS in the state file in plain text.

Verify it:
```bash
cat terraform.tfstate | grep -A2 "random_password"
```

You will see the actual value in the raw state JSON. This proves that
`sensitive = true` is display protection only — not encryption.

---

## Exercise 3 — terraform state pull (YOUR EXAM GAP)

This is the command you confused with refresh in Exam 4. Run it now.

```bash
terraform state pull
```

**What this does:** Downloads the raw state JSON from the configured backend
and prints it to stdout. For local backend this reads the local file.
For a remote backend (S3, Terraform Cloud) this fetches from the remote location.

**What this does NOT do:** It does not check actual infrastructure.
It does not refresh. It does not make any API calls to providers.
It reads from the backend storage — that is all.

```bash
# Pipe to jq for readable output
terraform state pull | python3 -m json.tool | head -60
```

**Contrast with terraform apply -refresh-only:**
```
terraform state pull        → reads state FROM the backend. No provider API calls.
terraform apply -refresh-only → checks ACTUAL infrastructure via provider APIs,
                                 then updates state to match what it found.
```

**The mental model:**
- `state pull` = download the state file. Storage operation.
- `apply -refresh-only` = go check if real infra matches state. Provider operation.

---

## Exercise 4 — terraform state rm (state-only removal)

We will remove one service from state without destroying it.

```bash
# First — verify it exists
terraform state list | grep service_id

# Remove it from state
terraform state rm 'module.app.random_id.service_id["auth"]'
```

Expected output:
```
Removed module.app.random_id.service_id["auth"]
Successfully removed 1 resource instance(s).
```

Now run plan:
```bash
terraform plan
```

**What you will see:** Terraform plans to CREATE `module.app.random_id.service_id["auth"]`
because it exists in the config but is no longer in state. The file still exists on disk —
terraform state rm did NOT delete it. But Terraform has forgotten it, so it will recreate it.

**Exam rule:** `terraform state rm` removes from state only. Real infrastructure is untouched.
After removal, Terraform will plan to create the resource again on next apply
(because config says it should exist and state says it doesn't).

```bash
# Restore state by re-applying
terraform apply -auto-approve
```

---

## Exercise 5 — terraform state mv (renaming in state)

This simulates refactoring — you renamed a resource in config and need to
tell Terraform it's the same resource, not destroy-old + create-new.

```bash
# See current address
terraform state list | grep summary

# Simulate: we want to rename deployment_summary to infra_summary in config.
# First move it in state (do this BEFORE changing the config):
terraform state mv \
  local_file.deployment_summary \
  local_file.deployment_summary_renamed
```

Now run plan — Terraform will show a diff because the config still says
`deployment_summary` but state now says `deployment_summary_renamed`.

```bash
terraform plan
```

Move it back to keep the project clean:
```bash
terraform state mv \
  local_file.deployment_summary_renamed \
  local_file.deployment_summary
```

**Real-world use:** When you refactor a configuration and rename resources,
`terraform state mv` prevents unnecessary destroy+create cycles. Always move
state BEFORE changing the configuration name to keep them in sync.

---

## Exercise 6 — terraform output (sensitive value behaviour)

```bash
# All outputs
terraform output

# Specific output
terraform output network_id

# Sensitive output — this will say: "The value is sensitive."
terraform output api_key

# -raw flag bypasses the sensitive guard
terraform output -raw api_key

# -json shows everything including sensitive values
terraform output -json
```

**Exam distinction:**
- `terraform output api_key` → `The value is sensitive. Use -raw to output it.`
- `terraform output -raw api_key` → prints the raw value
- `terraform output -json` → includes sensitive values in JSON
- The value is ALWAYS in plain text in the state file regardless

---

## State Operations Quick Reference

| Command | What it does to state | What it does to real infra |
|---|---|---|
| `terraform state list` | Lists all tracked resources | Nothing |
| `terraform state show ADDR` | Shows attributes of one resource | Nothing |
| `terraform state pull` | Downloads raw state JSON from backend | Nothing |
| `terraform state push FILE` | Uploads a local state file to backend | Nothing |
| `terraform state rm ADDR` | Removes resource from state | **Nothing** |
| `terraform state mv OLD NEW` | Renames resource address in state | Nothing |
| `terraform import ADDR ID` | Adds existing resource to state | Nothing |
| `terraform apply` | Updates state after making changes | **Creates/updates/destroys** |
| `terraform destroy` | Updates state after destroying | **Destroys** |
| `terraform apply -refresh-only` | Updates state to match real infra | Nothing |

**The rule:** If the command has `state` in it, it operates on state only.
Real infrastructure only changes when `apply` or `destroy` runs.
