# Clustered Web Server

Highly available web server using ASG and ALB.
Eliminates single point of failure from Day 3 single server.

## Architecture
User → ALB (port 80) → Target Group → ASG Instances (port 8080)

## Resources
- 2 Security Groups (ALB + Instance)
- Launch Template
- Auto Scaling Group (min 2, max 5)
- Application Load Balancer
- Target Group with health checks
- ALB Listener

## Usage
```bash
terraform init
terraform plan
terraform apply
# Wait 4-5 minutes for instances to pass health checks
terraform output  # get ALB DNS name
terraform destroy
```
