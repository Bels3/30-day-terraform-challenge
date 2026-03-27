# Day 15: Deploying Multi-Cloud Infrastructure with Terraform Modules

## What I Built

Three deployments in one day. A multi-provider module pattern using configuration_aliases that deploys S3 buckets across eu-west-1 and eu-west-2. An nginx Docker container running on localhost managed entirely by Terraform. A full EKS cluster with VPC, managed node groups, and a Kubernetes nginx deployment with 2 replicas.

## Key Concepts

- configuration_aliases for passing provider aliases into modules
- providers map in module calls for wiring providers
- Docker provider for local container management
- EKS cluster with Kubernetes provider authentication via exec block
- EKS access entries for IAM-based cluster authentication

## File Structure
```
day15/
  multi-provider-module/
    modules/multi-region-app/
      main.tf
      variables.tf
    live/
      main.tf
      backend.hcl
  docker/
    main.tf
    outputs.tf
  eks/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl
```

## Key Finding

EKS 1.29 uses access entries instead of aws-auth ConfigMap. Adding enable_cluster_creator_admin_permissions = true and an explicit access_entries block fixed the Unauthorized error on the Kubernetes deployment without reprovisioning the cluster.

## GitHub

[github.com/Bels3/30-day-terraform-challenge](https://github.com/Bels3/30-day-terraform-challenge)
