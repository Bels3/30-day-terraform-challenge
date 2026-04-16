terraform {
  backend "s3" {
    # All values injected via terraform init -backend-config=../backend.hcl
  }
}
