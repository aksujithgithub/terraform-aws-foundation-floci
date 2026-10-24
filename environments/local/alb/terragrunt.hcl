# -----------------------------------------------------------------------------
# environments/local/alb/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  tags     = local.env_vars.locals.common_tags
}

terraform {
  source = "../../../modules/alb"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id            = "vpc-00000000000000000"
    public_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "security_groups" {
  config_path = "../security-groups"

  mock_outputs = {
    alb_sg_id = "sg-00000000000000001"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vpc_id            = dependency.network.outputs.vpc_id
  public_subnet_ids = dependency.network.outputs.public_subnet_ids
  alb_sg_id         = dependency.security_groups.outputs.alb_sg_id
  tags              = local.tags
}
