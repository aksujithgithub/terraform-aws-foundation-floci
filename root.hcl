# -----------------------------------------------------------------------------
# root.hcl — Root Terragrunt configuration
# Inherited by all stacks via: include "root" { path = find_in_parent_folders("root.hcl") }
# -----------------------------------------------------------------------------

locals {
  # Derive environment name from directory path
  # e.g. environments/local/network -> "local"
  env = element(split("/", path_relative_to_include()), 1)

  project             = "terraform-aws-foundation"
  localstack_endpoint = "http://localhost:4566"
}

# ---------------------------------------------------------------------------
# Generate provider.tf into every stack's working directory
# ---------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "aws" {
      region                      = "us-east-1"
      access_key                  = "test"
      secret_key                  = "test"
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true

      endpoints {
        ec2                    = "${local.localstack_endpoint}"
        s3                     = "${local.localstack_endpoint}"
        iam                    = "${local.localstack_endpoint}"
        sts                    = "${local.localstack_endpoint}"
        route53                = "${local.localstack_endpoint}"
        elasticloadbalancing   = "${local.localstack_endpoint}"
        elbv2                  = "${local.localstack_endpoint}"
        rds                    = "${local.localstack_endpoint}"
        secretsmanager         = "${local.localstack_endpoint}"
      }
    }
  EOF
}

# ---------------------------------------------------------------------------
# Generate versions.tf into every stack's working directory
# ---------------------------------------------------------------------------
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    terraform {
      required_version = ">= 1.5.0"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 6.0"
        }
      }
    }
  EOF
}

# ---------------------------------------------------------------------------
# Local state backend — swap for S3 + DynamoDB in real environments
# ---------------------------------------------------------------------------
remote_state {
  backend = "local"

  config = {
    path = "${get_repo_root()}/.terragrunt-state/${local.env}/${path_relative_to_include()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# ---------------------------------------------------------------------------
# Common inputs passed to every stack
# ---------------------------------------------------------------------------
inputs = {
  project     = local.project
  environment = local.env
}
