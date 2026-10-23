#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# initial_setup.sh — one-time local dev environment setup
# Installs all tools required for terraform-aws-foundation local development
# -----------------------------------------------------------------------------

# Helper: print a section header
step() { echo ""; echo "===> $*"; }

# -----------------------------------------------------------------------------
# 1. floci (LocalStack wrapper)
# -----------------------------------------------------------------------------
step "Installing floci..."
brew install floci-io/floci/floci

step "Starting floci and injecting environment variables..."
floci start
eval "$(floci env)"

# -----------------------------------------------------------------------------
# 2. AWS CLI v2
# -----------------------------------------------------------------------------
step "Installing AWS CLI v2..."
curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash -s -- --system
echo "AWS CLI version: $(aws --version)"
echo "AWS CLI path:    $(which aws)"

# -----------------------------------------------------------------------------
# 3. Terraform
# -----------------------------------------------------------------------------
step "Installing Terraform..."
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
echo "Terraform version: $(terraform version -json | jq -r '.terraform_version')"

# -----------------------------------------------------------------------------
# 4. Terragrunt
# -----------------------------------------------------------------------------
step "Installing Terragrunt..."
brew install terragrunt
echo "Terragrunt version: $(terragrunt --version)"

# -----------------------------------------------------------------------------
# 5. TFLint (Terraform linter, used by pre-commit and CI)
# -----------------------------------------------------------------------------
step "Installing TFLint..."
brew install tflint
echo "TFLint version: $(tflint --version)"

# -----------------------------------------------------------------------------
# 6. terraform-docs (module documentation generator)
# -----------------------------------------------------------------------------
step "Installing terraform-docs..."
brew install terraform-docs
echo "terraform-docs version: $(terraform-docs --version)"

# -----------------------------------------------------------------------------
# 7. pre-commit
# -----------------------------------------------------------------------------
step "Installing pre-commit..."
brew install pre-commit
echo "pre-commit version: $(pre-commit --version)"

step "Installing pre-commit hooks into the repo..."
pre-commit install

# -----------------------------------------------------------------------------
# 8. jq (JSON parsing — used for reading Terragrunt/Terraform outputs)
# -----------------------------------------------------------------------------
step "Installing jq..."
brew install jq
echo "jq version: $(jq --version)"

# -----------------------------------------------------------------------------
# 9. Configure the 'floci' AWS profile
# -----------------------------------------------------------------------------
step "Configuring AWS 'floci' profile..."
aws configure set aws_access_key_id     test      --profile floci
aws configure set aws_secret_access_key test      --profile floci
aws configure set region                eu-west-1 --profile floci
aws configure set output                json      --profile floci

# Write endpoint_url to ~/.aws/config (not handled by aws configure set)
AWS_CONFIG_FILE="${HOME}/.aws/config"
if grep -q "\[profile floci\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
  if ! grep -A5 "\[profile floci\]" "$AWS_CONFIG_FILE" | grep -q "endpoint_url"; then
    sed -i '' "/\[profile floci\]/a\\
endpoint_url = http://localhost:4566
" "$AWS_CONFIG_FILE"
  fi
else
  cat >> "$AWS_CONFIG_FILE" <<'EOF'

[profile floci]
region       = eu-west-1
output       = json
endpoint_url = http://localhost:4566
EOF
fi

echo ""
echo "~/.aws/config [profile floci] block:"
grep -A5 "\[profile floci\]" "$AWS_CONFIG_FILE"

# -----------------------------------------------------------------------------
# 10. Verify LocalStack connectivity
# -----------------------------------------------------------------------------
step "Verifying connection to LocalStack..."
aws sts get-caller-identity --endpoint-url http://localhost:4566

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "========================================"
echo " All tools installed successfully"
echo "========================================"
echo ""
echo "  floci:          $(floci --version 2>/dev/null || echo 'check: floci --version')"
echo "  aws:            $(aws --version 2>&1 | head -1)"
echo "  terraform:      $(terraform version -json | jq -r '.terraform_version')"
echo "  terragrunt:     $(terragrunt --version)"
echo "  tflint:         $(tflint --version | head -1)"
echo "  terraform-docs: $(terraform-docs --version)"
echo "  pre-commit:     $(pre-commit --version)"
echo "  jq:             $(jq --version)"
echo ""
echo "Next steps:"
echo "  cd environments/local"
echo "  terragrunt run-all init"
echo "  terragrunt run-all plan"
echo "  terragrunt run-all apply"
