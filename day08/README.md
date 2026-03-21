# Day 8 - Building Reusable Infrastructure with Terraform Modules

## What I Built

A reusable Terraform module that packages an entire web server cluster
— ASG, ALB, Launch Template, Target Group, Listener, and Security Groups
— into a single callable component deployed across dev and production
with zero code duplication.

## The Problem Modules Solve

By Day 8 I had written the same security group structure, the same ASG
configuration, and the same ALB setup across four different days.
Every time I needed to change something I had to find every place it
appeared and update each one manually. Modules fix that permanently.

## Directory Structure
```
day08/
├── modules/
│   └── services/
│       └── webserver-cluster/
│           ├── main.tf        — all resource definitions
│           ├── variables.tf   — all configurable inputs
│           ├── outputs.tf     — all exposed values
│           └── README.md      — module documentation
└── live/
    ├── dev/
    │   └── services/
    │       └── webserver-cluster/
    │           └── main.tf    — calls module with dev values
    └── production/
        └── services/
            └── webserver-cluster/
                └── main.tf    — calls module with production values
```

## Module Inputs

| Variable | Type | Default | Description |
|---|---|---|---|
| cluster_name | string | required | Name prefix for all resources |
| instance_type | string | t2.micro | EC2 instance type |
| min_size | number | required | Minimum ASG instances |
| max_size | number | required | Maximum ASG instances |
| server_port | number | 8080 | HTTP port |
| ami | string | ami-0c38b837cd80f13bb | EC2 AMI |

## Module Outputs

| Output | Description |
|---|---|
| alb_dns_name | ALB DNS name for accessing the cluster |
| asg_name | Auto Scaling Group name |
| alb_security_group_id | ALB security group ID |

## How Dev and Production Differ

Same module. Different inputs. Zero code duplication.

Dev calling configuration:
- cluster_name = "webservers-dev"
- instance_type = "t2.micro"
- min_size = 2, max_size = 4

Production calling configuration:
- cluster_name = "webservers-production"
- instance_type = "t2.micro"
- min_size = 2, max_size = 5

## Deployment Confirmation

Dev cluster deployed and confirmed via browser at:
http://webservers-dev-alb-770186057.eu-west-1.elb.amazonaws.com

The cluster_name variable propagated all the way through to the
HTML page served by the instances — "webservers-dev" displayed
in the browser confirming the module input flowed correctly.

## Key Lessons

Writing infrastructure once and calling it multiple times with
different inputs is the difference between code that scales and
code that breaks under maintenance. Every hardcoded value is a
future bug waiting to happen.

## Remote State
- S3 Bucket: terraform-state-beldine-2026
- DynamoDB Table: terraform-state-locks
- Dev state: day08/live/dev/terraform.tfstate
- Production state: day08/live/production/terraform.tfstate

## Blog Post
Medium article coming soon

## Communities
- AWS AI/ML UserGroup Kenya
- Meru HashiCorp User Group
- EveOps
