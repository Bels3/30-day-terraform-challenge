variables {
  cluster_name  = "test-cluster"
  instance_type = "t2.micro"
  min_size      = 1
  max_size      = 2
  environment   = "dev"
}

run "validate_environment_variable" {
  command = plan

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment must be dev for unit tests."
  }
}

run "validate_instance_type_variable" {
  command = plan

  assert {
    condition     = var.instance_type == "t2.micro"
    error_message = "Instance type must be t2.micro for unit tests."
  }
}

run "validate_asg_capacity" {
  command = plan

  assert {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }

  assert {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

run "validate_cluster_name_prefix" {
  command = plan

  assert {
    condition     = var.cluster_name == "test-cluster"
    error_message = "cluster_name must be test-cluster for unit tests."
  }
}

run "validate_invalid_environment_rejected" {
  command = plan

  expect_failures = [var.environment]

  variables {
    environment = "invalid-env"
  }
}

run "validate_invalid_instance_type_rejected" {
  command = plan

  expect_failures = [var.instance_type]

  variables {
    instance_type = "m5.large"
  }
}
