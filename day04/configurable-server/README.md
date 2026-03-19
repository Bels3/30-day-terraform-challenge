# Configurable Web Server

Refactored Day 3 single server using input variables.
No hardcoded values in main.tf — everything driven by variables.tf.

## Usage
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## Variables
| Variable | Type | Default | Description |
|---|---|---|---|
| server_port | number | 8080 | Port the server listens on |
| instance_type | string | t2.micro | EC2 instance type |
| region | string | eu-west-1 | AWS region |
| server_name | string | terraform-day4-server | Instance name tag |
