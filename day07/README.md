# Day 7 - State Isolation: Workspaces vs File Layouts

## What I Built

### Activity 1 - Workspaces
Three isolated environments using Terraform workspaces:
- dev workspace
- staging workspace
- production workspace

Same codebase, separate state files under env:/ prefix in S3.

### Activity 2 - File Layouts
Three separate environment directories each with own backend:
- environments/dev — key: environments/dev/terraform.tfstate
- environments/staging — key: environments/staging/terraform.tfstate
- environments/production — key: environments/production/terraform.tfstate

### Activity 3 - Remote State Data Source
Staging environment reads dev security group ID directly
from dev state file in S3 without hardcoding.

## Key Comparison
Workspaces: same code, different state — easy to accidentally apply to wrong environment
File Layouts: separate code and state — stronger isolation, recommended for production

## Blog Post
[[Medium link](https://medium.com/@beldine3/state-isolation-workspaces-vs-file-layouts-when-to-use-each-9943287d761a)]
