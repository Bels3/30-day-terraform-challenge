# Day 25 — Static Website on AWS S3 + CloudFront

**30-Day Terraform Challenge · Beldine Oluoch**

A globally distributed static website deployed entirely through Terraform.
Modular configuration, remote state, environment isolation, and TF_LOG=DEBUG
used as a calibration tool rather than a debugging one.

## Project Structure

```
day25-static-website/
├── modules/
│   └── s3-static-website/      # Reusable module — all resource logic lives here
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── envs/
│   └── dev/                    # Calling configuration — clean, no hardcoded values
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── templates/
│   ├── index.html              # Website — dark editorial design, animated TF_LOG hero
│   └── error.html              # 404 page — styled as a Terraform error block
├── provider.tf
├── backend.hcl.example         # Copy to backend.hcl, fill in values, never commit
└── .gitignore
```

## Prerequisites

- Terraform >= 1.9.0
- AWS credentials configured (`aws configure` or environment variables)
- S3 state bucket already exists (`terraform-state-beldine-2026`)
- `backend.hcl` created from `backend.hcl.example` (never committed)

## Deploy

```bash
# 1. Copy and edit backend config (never commit this file)
cp backend.hcl.example backend.hcl
# Edit backend.hcl with your bucket, key, region

# 2. Enable debug logging (optional but recommended for first deploy)
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# 3. Initialize, plan, apply
cd envs/dev
terraform init -backend-config=../../backend.hcl
terraform validate
terraform plan -out=day25.tfplan
terraform apply "day25.tfplan"

# 4. Get the live URL
terraform output website_url

# 5. CloudFront takes 5-15 minutes to propagate globally after creation
# Test with: curl -I $(terraform output -raw website_url)
```

## After Content Updates

```bash
# Invalidate the CloudFront cache after updating index.html or error.html
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Destroy

```bash
cd envs/dev
terraform destroy
```

S3 objects are removed automatically. `force_destroy = true` is set for dev
and staging environments. Production is protected.

## TF_LOG Notes

Running `TF_LOG=DEBUG` on this project produces approximately 2,847 lines.
Key things visible in the log:

- CloudFront creation takes 144 seconds — provider polls every 15s
- `aws_s3_bucket_policy` pauses ~7s after the public access block for propagation
- State lock is acquired before any API calls are made
- The exact HTTP request and response for every AWS API call

Read the log after a clean apply (not just after failures) to verify your
mental model of the execution sequence.

## Resources Created

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Static website origin, versioning + SSE enabled |
| `aws_s3_bucket_website_configuration` | Static hosting enabled |
| `aws_s3_bucket_versioning` | Object version history |
| `aws_s3_bucket_server_side_encryption_configuration` | AES256 at rest |
| `aws_s3_bucket_public_access_block` | Selective public read |
| `aws_s3_bucket_policy` | GetObject for `*` principal |
| `aws_cloudfront_distribution` | CDN, HTTPS redirect, custom 404 |
| `aws_cloudwatch_log_group` | 30-day retention for CloudFront access |
| `aws_s3_object` ×2 | index.html and error.html |

**Total: 9 resources**

## Non-Negotiable Patterns (Day 1–25)

- Backend: empty `backend "s3" {}`, all values via `-backend-config`
- Variables: required variables have no defaults; safe defaults only where sensible
- Tags: `Environment`, `ManagedBy`, `Project`, `Owner`, `Day` on every resource
- Lock file: `.terraform.lock.hcl` committed (fixed on Day 24)
- `backend.hcl` in `.gitignore`, never committed

---

*github.com/Bels3/30-day-terraform-challenge*
