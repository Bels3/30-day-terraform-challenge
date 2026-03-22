# Day 4 - Mastering Basic Infrastructure with Terraform

## What I Built
1. Configurable web server using input variables
2. Highly available clustered web server with ASG and ALB

## Resources Created

### Configurable Server
- AWS Security Group
- AWS EC2 Instance (t2.micro)
- Input variables driving all configuration

### Clustered Server
- 2 AWS Security Groups (ALB + Instance)
- AWS Launch Template
- Auto Scaling Group (min 2, max 5 instances)
- Application Load Balancer
- Target Group with health checks
- ALB Listener

## Key Concepts
- DRY principle via input variables
- Data sources for dynamic AZ and subnet fetching
- Self-healing infrastructure via ASG
- Single entry point via ALB

## Blog Post
   [Medium]https://medium.com/@beldine3/deploying-a-highly-available-web-app-on-aws-using-terraform-2c392cb4e16f

## LinkedIn Post
   [LinkedIn](https://www.linkedin.com/feed/update/urn:li:activity:7440653389455187968/)
