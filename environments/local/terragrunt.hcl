# -----------------------------------------------------------------------------
# environments/local/terragrunt.hcl
# Environment-level config — overrides and locals for the local environment
# -----------------------------------------------------------------------------

locals {
  environment = "local"
  project     = "terraform-aws-foundation"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
  }
}
