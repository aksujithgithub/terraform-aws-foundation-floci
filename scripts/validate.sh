#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Starting Terragrunt/Terraform validation..."

# 1. Terraform format check (modules are plain .tf files)
echo ""
echo "--- Checking Terraform formatting ---"
terraform fmt -check -recursive "$ROOT_DIR/modules" || {
  echo "ERROR: Formatting issues found. Run 'terraform fmt -recursive modules/' to fix."
  exit 1
}
echo "Formatting OK"

# 2. Run terragrunt validate across all stacks in every environment
for env_dir in "$ROOT_DIR"/environments/*/; do
  env_name=$(basename "$env_dir")
  echo ""
  echo "--- Validating environment: $env_name ---"

  # run --all validate across all stacks in this environment
  terragrunt run --all validate \
    --terragrunt-working-dir "$env_dir" \
    --terragrunt-non-interactive

  echo "Environment '$env_name' validated"
done

echo ""
echo "==> All validations passed."
