# -----------------------------------------------------------------------------
# environments/local/security-groups/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  tags     = local.env_vars.locals.common_tags
}

terraform {
  source = "../../../modules/security-groups"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
  tags   = local.tags
}
