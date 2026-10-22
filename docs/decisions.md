# Architecture Decision Records

## ADR-001: Use floci for local AWS emulation

**Status:** Accepted

**Context:** We need a way to develop and test Terraform against AWS services without incurring costs or requiring a real AWS account for every engineer.

**Decision:** Use [floci](https://floci.io) (built on LocalStack) as the local AWS emulator. The `floci start` + `eval "$(floci env)"` pattern injects the necessary environment variables so the AWS CLI and Terraform provider automatically target `http://localhost:4566`.

**Consequences:** Local state is ephemeral — it resets on `floci stop`. CI/CD pipelines targeting real AWS will use separate environment configs.

---

## ADR-002: Module-per-concern structure

**Status:** Accepted

**Context:** A flat single-file Terraform configuration becomes hard to maintain as the infrastructure grows.

**Decision:** Split infrastructure into reusable modules (`network`, `iam`) consumed by environment-level roots (`environments/local`). Each environment only wires up the modules it needs.

**Consequences:** Slight increase in boilerplate, but strong separation of concerns and reusability across future environments (staging, prod).

---

## ADR-003: Skip remote backend for local environment

**Status:** Accepted

**Context:** LocalStack does not fully replicate S3-based Terraform remote state.

**Decision:** The `local` environment uses the default local state file. Real environments will define an S3 + DynamoDB backend.

**Consequences:** Local state is not shared. This is acceptable since local is a single-developer environment.
