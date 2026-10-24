# -----------------------------------------------------------------------------
# environments/local/ec2/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  tags     = local.env_vars.locals.common_tags
}

terraform {
  source = "../../../modules/ec2"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    private_subnet_ids = ["subnet-00000000000000003", "subnet-00000000000000004"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "security_groups" {
  config_path = "../security-groups"

  mock_outputs = {
    ec2_sg_id = "sg-00000000000000002"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "iam" {
  config_path = "../iam"

  mock_outputs = {
    ec2_instance_profile_name = "mock-instance-profile"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "alb" {
  config_path = "../alb"

  mock_outputs = {
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:000000000000:targetgroup/mock/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs = {
    secret_name = "mock-project/local/db"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  private_subnet_ids   = dependency.network.outputs.private_subnet_ids
  ec2_sg_id            = dependency.security_groups.outputs.ec2_sg_id
  iam_instance_profile = dependency.iam.outputs.ec2_instance_profile_name
  target_group_arn     = dependency.alb.outputs.target_group_arn
  db_secret_name       = dependency.rds.outputs.secret_name
  aws_region           = "us-east-1"
  localstack_endpoint  = "http://localhost:4566"
  instance_count       = 1
  tags                 = local.tags
}
