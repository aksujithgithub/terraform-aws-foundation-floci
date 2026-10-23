# -----------------------------------------------------------------------------
# environments/local/env.hcl
# Plain locals file — read by stacks via read_terragrunt_config()
# Contains no Terragrunt directives (no skip, no include, no generate)
# so it is safe to read_terragrunt_config() from child stacks.
# -----------------------------------------------------------------------------

locals {
  environment = "local"
  project     = "terraform-aws-foundation"

  common_tags = {
    Environment = "local"
    Project     = "terraform-aws-foundation"
    ManagedBy   = "terragrunt"
  }
}
