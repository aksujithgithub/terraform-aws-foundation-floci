# terraform-aws-foundation

Foundational AWS infrastructure with Terraform modules, orchestrated by [Terragrunt](https://terragrunt.gruntwork.io) and designed for local development via [floci](https://floci.io) (LocalStack).

## Prerequisites

| Tool | Purpose | Min version |
|---|---|---|
| [floci](https://floci.io) | Local AWS emulator (LocalStack wrapper) | latest |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | Interact with LocalStack | v2 |
| [Terraform](https://developer.hashicorp.com/terraform/install) | Infrastructure provisioning | >= 1.5 |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | Environment orchestration | >= 1.0 |
| [TFLint](https://github.com/terraform-linters/tflint) | Terraform linter | latest |
| [terraform-docs](https://terraform-docs.io) | Module documentation | latest |
| [pre-commit](https://pre-commit.com) | Git hook runner | latest |
| [jq](https://jqlang.github.io/jq/) | JSON output parsing | latest |

Run `initial_setup.sh` to install everything in one shot (see [Setup](#setup) below).

---

## Setup

Run the one-time setup script — it installs all tools, configures the AWS `floci` profile, and verifies LocalStack connectivity:

```bash
bash initial_setup.sh
```

What it does, in order:

| Step | Action |
|---|---|
| 1 | Install floci, start it, inject env vars |
| 2 | Install AWS CLI v2 |
| 3 | Install Terraform (via Homebrew hashicorp tap) |
| 4 | Install Terragrunt |
| 5 | Install TFLint |
| 6 | Install terraform-docs |
| 7 | Install pre-commit and register git hooks |
| 8 | Install jq |
| 9 | Configure `~/.aws/config` with the `floci` profile + LocalStack endpoint |
| 10 | Verify LocalStack with `aws sts get-caller-identity` |

### Manual setup (step by step)

### Manual setup (step by step)

### 1. Install floci

```bash
brew install floci-io/floci/floci
```

### 2. Install the AWS CLI

```bash
brew install awscli
aws --version
which aws
```

### 3. Configure the `floci` AWS profile

```bash
aws configure set aws_access_key_id     test        --profile floci
aws configure set aws_secret_access_key test        --profile floci
aws configure set region                eu-west-1   --profile floci
aws configure set output                json        --profile floci
```

This writes the following to `~/.aws/config`:

```ini
[profile floci]
region     = eu-west-1
output     = json
endpoint_url = http://localhost:4566
```

> The `endpoint_url` key redirects all AWS CLI calls to LocalStack automatically when using `--profile floci`, so you don't need `--endpoint-url` on every command.

### 4. Start floci and activate its environment

```bash
floci start
eval "$(floci env)"
```

### 5. Verify connectivity

```bash
aws sts get-caller-identity --endpoint-url http://localhost:4566
# or, using the profile:
aws sts get-caller-identity --profile floci
```

Expected output:
```json
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "000000000000",
    "Arn": "arn:aws:iam::000000000000:root"
}
```

---

## Usage

### Deploy all stacks

```bash
cd environments/local
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply
```

Terragrunt resolves the dependency order automatically:
```
network → security-groups → iam → alb → rds → ec2
```

### Test the CRUD API

After apply, get the ALB DNS name:
```bash
cd environments/local/alb
terragrunt output alb_dns_name
```

Then hit the endpoints (replace `<ALB_DNS>` with the output):
```bash
# Health check
curl http://<ALB_DNS>/health

# Create an item
curl -X POST http://<ALB_DNS>/items \
  -H "Content-Type: application/json" \
  -d '{"name": "widget", "description": "a test item"}'

# List all items
curl http://<ALB_DNS>/items

# Get one item
curl http://<ALB_DNS>/items/1

# Update an item
curl -X PUT http://<ALB_DNS>/items/1 \
  -H "Content-Type: application/json" \
  -d '{"description": "updated description"}'

# Delete an item
curl -X DELETE http://<ALB_DNS>/items/1
```

For LocalStack, the ALB DNS resolves to `localhost` — use:
```bash
curl http://localhost:4566/_localstack/health   # verify services
curl http://localhost/health                    # via ALB (port 80)
```

### Deploy a single stack

```bash
# Network only
cd environments/local/network
terragrunt init
terragrunt plan
terragrunt apply

# IAM only (network must already be applied)
cd environments/local/iam
terragrunt init
terragrunt plan
terragrunt apply
```

### View outputs

```bash
cd environments/local/network
terragrunt output

cd environments/local/iam
terragrunt output
```

### Tear down

```bash
# Single stack
cd environments/local/iam
terragrunt destroy

# Everything, in reverse dependency order
cd environments/local
terragrunt run --all destroy
```

### Validate & format

```bash
# Run fmt check + terragrunt validate across all stacks
bash scripts/validate.sh

# Format modules in place
terraform fmt -recursive modules/
```

---

## Project Structure

```
├── root.hcl                        # Root: generates provider, versions, backend
├── environments/
│   └── local/
│       ├── env.hcl                 # Env locals (tags, environment name)
│       ├── network/                # VPC, subnets, IGW, route tables
│       ├── security-groups/        # ALB, EC2, RDS security groups
│       ├── iam/                    # EC2 role + instance profile
│       ├── alb/                    # Application Load Balancer + target group
│       ├── rds/                    # MySQL RDS instance in private subnets
│       └── ec2/                    # EC2 instances in private subnets
├── modules/
│   ├── network/                    # VPC, subnets, IGW, route tables
│   ├── security-groups/            # ALB / EC2 / RDS security groups
│   ├── iam/                        # Roles, instance profiles
│   ├── alb/                        # ALB, listener, target group
│   ├── ec2/                        # EC2 instances + ALB attachment
│   └── rds/                        # RDS MySQL + subnet group
├── app/
│   ├── app.py                      # Flask CRUD application
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── scripts/
│   └── validate.sh
├── docs/
│   ├── architecture.md
│   └── decisions.md
└── .github/
    └── workflows/
        └── terraform.yml
```

---

## Adding a New Environment

1. Create `environments/<env>/terragrunt.hcl` with environment-specific locals
2. Add per-stack subdirectories (`network/`, `iam/`) each with a `terragrunt.hcl` that points at the same modules
3. Override inputs (CIDRs, region, tags) as needed — the root config handles provider and backend generation automatically

---

## Pre-commit Hooks

Hooks are installed automatically by `initial_setup.sh`. To install manually:

```bash
pre-commit install
```

Hooks run `terraform_fmt`, `terraform_validate`, and `tflint` on every commit.

---

## Docs

- [Architecture](docs/architecture.md)
- [Decisions](docs/decisions.md)
