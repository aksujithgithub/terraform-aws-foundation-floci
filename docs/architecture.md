# Architecture

## Overview

This project provisions a foundational AWS infrastructure using Terraform modules orchestrated by [Terragrunt](https://terragrunt.gruntwork.io), designed to run locally via [floci](https://floci.io) (LocalStack-based).

## Structure

```
terragrunt.hcl                    # Root: generates provider + versions, configures backend
environments/
  local/
    terragrunt.hcl                # Env-level locals (tags, env name)
    network/
      terragrunt.hcl              # Stack: calls modules/network, sets CIDR inputs
    iam/
      terragrunt.hcl              # Stack: calls modules/iam, depends on network
modules/
  network/                        # Pure Terraform — VPC, subnets, routing
  iam/                            # Pure Terraform — roles, instance profiles
```

## Terragrunt Hierarchy

```
Root terragrunt.hcl
  └── environments/local/terragrunt.hcl   (env locals)
        ├── network/terragrunt.hcl         (stack)
        └── iam/terragrunt.hcl             (stack, depends on network)
```

The root config generates `provider.tf`, `versions.tf`, and `backend.tf` into each stack's working directory at `init` time — no duplication across stacks.

## Network Layout

```
VPC (10.0.0.0/16)
├── Public Subnets  (10.0.1.0/24, 10.0.2.0/24)  — internet-facing resources
└── Private Subnets (10.0.11.0/24, 10.0.12.0/24) — internal resources
```

An Internet Gateway is attached with a route table associated to public subnets.

## IAM

A base EC2 instance role and instance profile are created per environment.

## Local Development

All traffic routes to `http://localhost:4566` (LocalStack) via the floci-managed environment. The provider block targeting LocalStack is generated automatically by the root `terragrunt.hcl` — no manual provider config needed per stack.

See [decisions.md](./decisions.md) for design rationale.
