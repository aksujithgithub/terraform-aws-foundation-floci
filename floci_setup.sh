#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# floci_setup.sh — one-time local dev environment setup
# -----------------------------------------------------------------------------

# 1. Install floci
brew install floci-io/floci/floci

# 2. Start floci (LocalStack) and inject its environment variables
floci start
eval "$(floci env)"

# 3. Install AWS CLI v2
curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash -s -- --system
aws --version
which aws

# 4. Configure the 'floci' AWS profile (uses test credentials for LocalStack)
aws configure set aws_access_key_id     test      --profile floci
aws configure set aws_secret_access_key test      --profile floci
aws configure set region                eu-west-1 --profile floci
aws configure set output                json      --profile floci

# 5. Write the endpoint_url to ~/.aws/config so the CLI targets LocalStack
#    automatically when using --profile floci (no need for --endpoint-url)
AWS_CONFIG_FILE="${HOME}/.aws/config"
if grep -q "\[profile floci\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
  # Already present — ensure endpoint_url is set
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

# 6. Verify connectivity
echo ""
echo "Verifying connection to LocalStack..."
aws sts get-caller-identity --endpoint-url http://localhost:4566
