# -----------------------------------------------------------------------------
# environments/local/terragrunt.hcl
# Environment-level config — overrides and locals for the local environment
# Not a deployable unit; skip = true prevents run --all from treating it as one
# -----------------------------------------------------------------------------

# Prevent terragrunt run --all from treating this as a deployable stack
skip = true

locals {
  environment = "local"
  project     = "terraform-aws-foundation"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
  }
}
