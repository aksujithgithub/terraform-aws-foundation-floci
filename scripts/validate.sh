#!/usr/bin/env bash
set -euo pipefail

# Validate all Terraform configurations in the repo
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Starting Terraform validation..."

# Format check
echo ""
echo "--- Checking formatting ---"
terraform fmt -check -recursive "$ROOT_DIR" || {
  echo "ERROR: Formatting issues found. Run 'terraform fmt -recursive .' to fix."
  exit 1
}
echo "Formatting OK"

# Validate each environment
for env_dir in "$ROOT_DIR"/environments/*/; do
  env_name=$(basename "$env_dir")
  echo ""
  echo "--- Validating environment: $env_name ---"
  terraform -chdir="$env_dir" init -backend=false -input=false > /dev/null
  terraform -chdir="$env_dir" validate
  echo "Environment '$env_name' is valid"
done

echo ""
echo "==> All validations passed."
