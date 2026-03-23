terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"
}

locals {
  instance_type = var.environment == "production" ? "t2.medium" : "t2.micro"
}

# COUNT EXAMPLE
resource "aws_iam_user" "count_example" {
  count = length(var.user_names)
  name  = "day10-count-${var.user_names[count.index]}"
}

# FOR_EACH EXAMPLE — set
resource "aws_iam_user" "foreach_set_example" {
  for_each = toset(var.user_names)
  name     = "day10-foreach-${each.value}"
}

# FOR_EACH EXAMPLE — map
resource "aws_iam_user" "foreach_map_example" {
  for_each = var.users
  name     = "day10-map-${each.key}"

  tags = {
    Department = each.value.department
    Admin      = tostring(each.value.admin)
  }
}

# CONDITIONAL — autoscaling toggle
resource "aws_iam_user" "conditional_example" {
  count = var.enable_autoscaling ? 1 : 0
  name  = "day10-conditional-user"
}
