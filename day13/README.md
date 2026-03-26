# Day 13: Managing Sensitive Data Securely in Terraform

## What I Built

A secure secrets management setup using AWS Secrets Manager and Terraform. Database credentials are stored in Secrets Manager, fetched at runtime via data sources, and never appear in any .tf file. Sensitive outputs are marked with sensitive = true to prevent values appearing in terminal output and logs.

## Key Concepts

- Three secret leak paths and how to close each one
- AWS Secrets Manager integration using data sources
- sensitive = true for variables and outputs
- write-only attributes in Terraform 1.14
- State file encryption at rest using S3 backend

## File Structure
```
day13/
  secrets-management/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl        ← never committed
```

## How to Deploy
```bash
# Create the secret manually first — never through Terraform
aws secretsmanager create-secret \
  --name "prod/db/credentials" \
  --secret-string '{"username":"dbadmin","password":"your-password"}' \
  --region eu-west-1

# Then deploy
terraform init -backend-config=backend.hcl
terraform plan
terraform apply -auto-approve
```

## Verification Commands
```bash
# View sensitive output explicitly
terraform output db_endpoint

# Verify secret in Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id "prod/db/credentials" \
  --region eu-west-1 \
  --query 'SecretString' \
  --output text

# Check password handling in state
terraform show | grep -i password
```

## Key Finding

Running `terraform show | grep -i password` returned `password_wo = (write-only attribute)` — meaning the password is never stored in state at all in Terraform 1.14. This is stronger protection than sensitive = true alone.

## GitHub

[github.com/Bels3/30-day-terraform-challenge](https://github.com/Bels3/30-day-terraform-challenge)
