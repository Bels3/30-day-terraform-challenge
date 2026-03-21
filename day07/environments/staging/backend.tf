terraform {
  backend "s3" {
    bucket         = "terraform-state-beldine-2026"
    key            = "environments/staging/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
