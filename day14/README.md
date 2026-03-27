# Day 14: Working with Multiple Providers in Terraform

## What I Built

Cross-region S3 replication between eu-west-1 and eu-west-2 using provider aliases. A single Terraform configuration deploys resources to two AWS regions in one apply. Replication was verified by uploading a test file to the primary bucket and confirming it appeared in the replica within 30 seconds.

## Key Concepts

- Provider aliases for multi-region deployments
- .terraform.lock.hcl — what it records and why it gets committed
- Version constraint operators — ~> vs >= vs =
- assume_role for multi-account deployments
- S3 versioning required for cross-region replication

## File Structure
```
day14/
  multi-region/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl        ← never committed
```

## How to Deploy
```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply -auto-approve

# Verify replication
echo "test" > test.txt
aws s3 cp test.txt s3://beldine-day14-primary/ --region eu-west-1
aws s3 ls s3://beldine-day14-replica/ --region eu-west-2
```

## Key Finding

Two provider blocks in one main.tf — one default for eu-west-1, one aliased for eu-west-2. Resources referencing `provider = aws.eu_west_2` deploy to London. Everything else deploys to Ireland. One apply handles both.

## GitHub

[github.com/Bels3/30-day-terraform-challenge](https://github.com/Bels3/30-day-terraform-challenge)
