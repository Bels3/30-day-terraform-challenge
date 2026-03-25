# Day 12: Zero-Downtime Deployments with Terraform

## What I Built

A production-grade blue/green deployment system using Terraform, AWS Auto Scaling Groups, and an Application Load Balancer. The setup demonstrates two zero-downtime strategies: `create_before_destroy` lifecycle rules for rolling instance updates, and blue/green switching at the ALB listener rule level for instant traffic shifts.

## The Problem with Default Terraform

When you update a Launch Template, Terraform's default behaviour is destroy first, then create. For an ASG this means your instances are terminated before new ones exist. Your application goes down. For any production service this is unacceptable.

## The Fix

Two strategies working together:

**1. create_before_destroy** — reverses the order of operations. New instances are created and pass health checks before old ones are destroyed. Traffic never drops.

**2. Blue/Green switching** — two complete environments run simultaneously. Traffic shifts at the ALB listener rule level in a single API call. The switch takes one second.

## File Structure
```
day12/
  webserver-cluster/
    main.tf
    variables.tf
    outputs.tf
    user-data.sh
    backend.hcl        ← never committed
```

## How to Deploy
```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply -auto-approve
```

## How to Switch Blue/Green
```bash
# Switch to green
terraform apply -var="active_environment=green" -auto-approve

# Switch back to blue
terraform apply -var="active_environment=blue" -auto-approve
```

The listener rule updates in under 2 seconds. Zero downtime. Zero destroyed resources.

## How to Trigger a Zero-Downtime Version Update

Update `user-data.sh`, then apply:
```bash
terraform apply -auto-approve
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name <your-asg-name> \
  --region eu-west-1
```

New instances come up with the new version. Old instances are terminated only after new ones pass health checks.

## Key Concepts

- `create_before_destroy` lifecycle rule on Launch Template and ASG
- `name_prefix` instead of `name` on ASGs and target groups — avoids naming conflicts during replacement
- IMDSv2 compliant metadata fetch using token-based requests
- `aws_launch_template` over deprecated `aws_launch_configuration`
- All ports driven by variables — no hardcoded values

## Verification Commands
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --query 'TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State}' \
  --output table

# Watch instance refresh progress
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name <asg-name> \
  --query 'InstanceRefreshes[0].{Status:Status,PercentComplete:PercentageComplete}' \
  --output table
```

## Medium Article

Coming soon.

## GitHub

[github.com/Bels3/30-day-terraform-challenge](https://github.com/Bels3/30-day-terraform-challenge)
