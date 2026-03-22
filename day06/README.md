# Day 6 — Understanding and Managing Terraform State

## What I Built
1. Remote backend infrastructure — S3 bucket and DynamoDB table
2. Infrastructure using the remote backend with state migration
3. State locking demonstration

## Folder Structure
```
day06/
├── remote-backend/    # S3 bucket + DynamoDB table for state storage
│   └── main.tf
└── infrastructure/    # Example infrastructure using remote backend
    └── main.tf
```

## Key Concepts Covered

### The Bootstrap Problem
Cannot use Terraform to create the backend that Terraform needs.
The S3 bucket must exist before Terraform can store state in it.
Solution: create backend infrastructure first as a separate operation.

### Remote Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day06/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### Backend Arguments Explained
- bucket: S3 bucket storing the state file
- key: path within the bucket — keeps each environment separate
- region: must match the bucket region
- dynamodb_table: table used for state locking
- encrypt: encrypts state file in transit and at rest

### State Migration
Started with local state, added backend block, ran:
```bash
terraform init -migrate-state
```
Terraform detected existing local state and asked permission
to copy it to S3. After confirming, state lived in S3 —
versioned, encrypted, and team-accessible.

### State Backup Behaviour
When Terraform prepared to migrate it automatically created
terraform.tfstate.backup before making any changes.
Terraform never overwrites state — it always preserves
the previous state as a backup first.

### State Locking Test
Ran terraform apply in Terminal 1.
Immediately ran terraform plan in Terminal 2.
DynamoDB rejected the second operation with:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        e9bae314-4501-1856-1f41-e10614457a2e
  Path:      terraform-state-beldine-2026/day06/terraform.tfstate
  Operation: OperationTypeApply
  Who:       beldine@beldine-HP-Notebook
  Version:   1.14.7
  Created:   2026-03-20 10:09:45
```

The lock shows who holds it, what operation caused it,
and when it was created. In a team this prevents two
engineers from corrupting state simultaneously.

## State File Observations

### terraform state list
```
aws_s3_bucket.example
aws_security_group.example
```

### terraform state show aws_s3_bucket.example
Shows full resource detail — ARN, bucket domain name,
region, encryption config, versioning status, tags,
and canonical user grant. Every attribute Terraform
knows about the resource is recorded.

## Why State Should Never Be in Git
The state file contains AWS Account IDs, resource ARNs,
VPC IDs, subnet IDs, and full resource configurations.
Committing it to a public repo exposes your entire
infrastructure layout. It also changes on every apply
creating constant merge conflicts.

Always add to .gitignore:
```
*.tfstate
*.tfstate.backup
.terraform/
```

## S3 Bucket Security Features
- prevent_destroy = true: protects bucket from accidental deletion
- Versioning enabled: every state change creates a new version
- Server side encryption AES256: encrypts state at rest
- Public access block: state never publicly accessible

## Blog Post
[Medium post published.](https://medium.com/@beldine3/how-to-securely-store-terraform-state-files-with-remote-backends-af612c45e753)

## Social Media
[LinkedIn post](https://www.linkedin.com/feed/update/urn:li:activity:7441378131292274688/).

## GitHub
https://github.com/Bels3/30-day-terraform-challenge/tree/master/day06
