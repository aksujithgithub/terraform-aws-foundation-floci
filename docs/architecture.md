# Architecture

## Overview

This project provisions a foundational AWS infrastructure using Terraform, designed to run locally via [floci](https://floci.io) (LocalStack-based).

## Structure

```
environments/
  local/        # Local dev environment wired to LocalStack via floci
modules/
  network/      # VPC, subnets, routing
  iam/          # Roles and instance profiles
```

## Network Layout

```
VPC (10.0.0.0/16)
├── Public Subnets  (10.0.1.0/24, 10.0.2.0/24)  — internet-facing resources
└── Private Subnets (10.0.11.0/24, 10.0.12.0/24) — internal resources
```

An Internet Gateway is attached to the VPC with a route table associated to public subnets.

## IAM

A base EC2 instance role and instance profile are created per environment for use by compute resources.

## Local Development

Traffic is routed to `http://localhost:4566` (LocalStack) via the floci-managed environment. See [decisions.md](./decisions.md) for rationale.
