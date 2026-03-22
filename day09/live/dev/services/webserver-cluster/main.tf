terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "day09/live/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

module "webserver_cluster" {
  source = "github.com/Bels3/terraform-aws-webserver-cluster?ref=v0.0.2"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4

  custom_tags = {
    Environment = "dev"
    Version     = "v0.0.2"
    Challenge   = "30-day-terraform"
  }
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
