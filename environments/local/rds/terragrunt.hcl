# -----------------------------------------------------------------------------
# environments/local/rds/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  tags     = local.env_vars.locals.common_tags
}

terraform {
  source = "../../../modules/rds"
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
    rds_sg_id = "sg-00000000000000003"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  rds_sg_id          = dependency.security_groups.outputs.rds_sg_id
  db_name            = "appdb"
  db_username        = "admin"
  db_password        = "localstack-dev-password"
  tags               = local.tags
}
