run "validate_instance_type" {
  command = plan

  variables {
    cluster_name  = "day22-test"
    environment   = "test"
    instance_type = "t2.micro"
    ami_id        = "ami-03957e4cfe042cca1"
    min_size      = 1
    max_size      = 2
    owner         = "Beldine Oluoch"
    project_name  = "30-day-terraform-challenge"
  }

  assert {
    condition     = aws_launch_template.webserver.instance_type == "t2.micro"
    error_message = "Instance type must be t2.micro"
  }
}

run "validate_imdsv2" {
  command = plan

  variables {
    cluster_name  = "day22-test"
    environment   = "test"
    instance_type = "t2.micro"
    ami_id        = "ami-03957e4cfe042cca1"
    min_size      = 1
    max_size      = 2
    owner         = "Beldine Oluoch"
    project_name  = "30-day-terraform-challenge"
  }

  assert {
    condition     = aws_launch_template.webserver.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced"
  }
}

run "validate_tags" {
  command = plan

  variables {
    cluster_name  = "day22-test"
    environment   = "test"
    instance_type = "t2.micro"
    ami_id        = "ami-03957e4cfe042cca1"
    min_size      = 1
    max_size      = 2
    owner         = "Beldine Oluoch"
    project_name  = "30-day-terraform-challenge"
  }

  assert {
    condition     = aws_launch_template.webserver.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must be set to terraform"
  }
}
