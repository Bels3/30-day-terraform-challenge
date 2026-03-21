# Webserver Cluster Module

Reusable module that deploys a highly available web server cluster
on AWS using an Auto Scaling Group and Application Load Balancer.

## Usage
```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
}
```

## Inputs

| Variable | Type | Default | Description |
|---|---|---|---|
| cluster_name | string | required | Name for all cluster resources |
| instance_type | string | t2.micro | EC2 instance type |
| min_size | number | required | Minimum ASG instances |
| max_size | number | required | Maximum ASG instances |
| server_port | number | 8080 | HTTP port |
| ami | string | ami-0c38b837cd80f13bb | EC2 AMI |

## Outputs

| Output | Description |
|---|---|
| alb_dns_name | ALB DNS name |
| asg_name | Auto Scaling Group name |
| alb_security_group_id | ALB security group ID |
