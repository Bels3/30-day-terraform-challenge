terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day09/live/production/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

module "webserver_cluster" {
  source = "github.com/Bels3/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name  = "webservers-production"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 5
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
