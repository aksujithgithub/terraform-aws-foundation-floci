# -----------------------------------------------------------------------------
# environments/local/network/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders()
}

# Pull environment-level locals
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl", "environments/local/terragrunt.hcl"))
  tags     = local.env_vars.locals.common_tags
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  tags                 = local.tags
}
