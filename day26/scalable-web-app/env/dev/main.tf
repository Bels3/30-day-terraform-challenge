# DAY 26: MAIN CONFIGURATION
# Scalable Web Application with Auto Scaling
# All infrastructure provisioned via Terraform

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Owner       = var.owner
    Day         = "26"
    Challenge   = "30-Day-Terraform"
  }
}

# MODULE: VPC - Complete Networking Stack
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
  vpc_cidr     = var.vpc_cidr
}

# MODULE: EC2 Launch Template
module "ec2" {
  source = "../../modules/ec2"

  ami_id        = var.ami_id
  instance_type = var.instance_type
  environment   = var.environment
  project_name  = var.project_name
  owner         = var.owner
  vpc_id        = module.vpc.vpc_id
  server_port   = var.server_port
  aws_region    = var.aws_region

  # Scaling variables for user_data template
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
  
  alb_security_group_id = module.alb.alb_security_group_id

  # Optional configurations
  key_name    = null
  volume_size = 20
  volume_type = "gp3"
}

# MODULE: Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  name                       = var.cluster_name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  environment                = var.environment
  project_name               = var.project_name
  owner                      = var.owner
  server_port                = var.server_port
  instance_security_group_id = module.ec2.security_group_id

  # Dev-specific configurations
  enable_deletion_protection = false
  idle_timeout               = 60
  access_logs_bucket         = null
  ssl_certificate_arn        = null
}

# MODULE: Auto Scaling Group
module "asg" {
  source = "../../modules/asg"

  name                    = var.cluster_name
  launch_template_id      = module.ec2.launch_template_id
  launch_template_version = module.ec2.launch_template_version
  subnet_ids              = module.vpc.private_subnet_ids
  target_group_arns       = [module.alb.target_group_arn]
  environment             = var.environment
  project_name            = var.project_name
  owner                   = var.owner
  aws_region              = var.aws_region

  # Scaling configuration
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # CPU thresholds
  cpu_scale_out_threshold = var.cpu_alarm_threshold
  cpu_scale_in_threshold  = 30

  # Health check settings
  health_check_grace_period = 300

  # Dev-specific
  enable_scale_in_protection = false

  # Wire ALB alarm to ASG scaling
}
