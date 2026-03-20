# Day 5 - Scaling Infrastructure and Understanding Terraform State

## What I Built
Scaled infrastructure with ALB + ASG, then explored Terraform state management through hands-on experiments.

## Resources Created
- 2 Security Groups (ALB + Instance)
- Launch Template
- Auto Scaling Group (min 2, max 5 across 3 AZs)
- Application Load Balancer
- Target Group with health checks
- ALB Listener

## State Experiments
**Experiment 1 — Manual state file tampering**
Edited terraform.tfstate directly changing instance type from t2.micro to t2.large.
Result: No changes detected. Terraform trusted real AWS infrastructure over the tampered state file.

**Experiment 2 — AWS Console drift detection**
Part A: Added manual tag to ASG EC2 instance — no drift detected because Terraform does not directly manage ASG instances.
Part B: Added manual tag to ALB security group — drift detected immediately. Terraform proposed to remove the unauthorized tag and restore configured state.

## Key Learnings
- State file stores complete record of all resources — ARNs, IDs, tags, dependencies
- Never edit state file directly — use terraform state commands
- Never commit state to Git — contains sensitive account information
- Remote state in S3 enables team collaboration
- State locking via DynamoDB prevents concurrent apply conflicts
- Terraform only detects drift on resources it directly manages

## Blog Post
🔗 [[Insert Medium link here](https://medium.com/@beldine3/managing-high-traffic-applications-with-aws-elastic-load-balancer-and-terraform-e147131a7170)]
