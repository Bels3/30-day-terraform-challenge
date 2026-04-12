module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name    = var.bucket_name
  environment    = var.environment
  owner          = var.owner
  project_name   = var.project_name
  index_document = var.index_document
  error_document = var.error_document
  price_class    = var.price_class

  tags = {
    Day       = "25"
    Challenge = "30-day-terraform-challenge"
  }
}
