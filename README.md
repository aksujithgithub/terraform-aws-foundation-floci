# terraform-aws-foundation

Foundational AWS infrastructure with Terraform, designed for local development via [floci](https://floci.io) (LocalStack).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [floci](https://floci.io) — install via Homebrew:
  ```bash
  brew install floci-io/floci/floci
  ```
- [pre-commit](https://pre-commit.com) (optional, for git hooks)

## Quick Start

```bash
# 1. Start the local AWS emulator
floci start
eval "$(floci env)"

# 2. Verify connectivity
aws sts get-caller-identity --endpoint-url http://localhost:4566

# 3. Deploy the local environment
cd environments/local
terraform init
terraform plan
terraform apply
```

## Project Structure

```
├── environments/
│   └── local/          # Local dev environment (targets LocalStack via floci)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── provider.tf
│       └── versions.tf
├── modules/
│   ├── network/        # VPC, subnets, routing, IGW
│   └── iam/            # Roles and instance profiles
├── scripts/
│   └── validate.sh     # Run fmt + validate across all environments
├── docs/
│   ├── architecture.md
│   └── decisions.md
└── .github/
    └── workflows/
        └── terraform.yml  # CI: fmt check, validate, tflint
```

## Validation

```bash
bash scripts/validate.sh
```

## Pre-commit Hooks

```bash
pre-commit install
```

Hooks run `terraform fmt`, `terraform validate`, and `tflint` on every commit.

## Docs

- [Architecture](docs/architecture.md)
- [Decisions](docs/decisions.md)
