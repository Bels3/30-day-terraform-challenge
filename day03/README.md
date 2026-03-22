# Day 3 - Deploying Your First Server with Terraform

## What I Built
A web server on AWS EC2 provisioned entirely with Terraform.

## Resources Created
- AWS Security Group (HTTP port 80 inbound)
- AWS EC2 Instance (t2.micro, Amazon Linux)
- User data script serving a custom HTML page

## Terraform Workflow
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## Key Challenge
Heredoc delimiter issue in user_data script — fixed by changing `<<HTML` to `<<-HTML`

## Blog Post
 [[Medium link]](https://medium.com/@beldine3/deploying-your-first-server-with-terraform-a-beginners-guide-3b3d4e008c81)

## LinkedIn Post
   [LinkedIn](https://www.linkedin.com/feed/update/urn:li:activity:7440291462488961024/)
