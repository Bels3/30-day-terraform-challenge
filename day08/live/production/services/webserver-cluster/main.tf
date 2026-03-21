terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day08/live/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the dev load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "The name of the dev Auto Scaling Group"
}
