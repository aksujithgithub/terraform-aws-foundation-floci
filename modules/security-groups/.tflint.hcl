# modules/.tflint.hcl
# Disable version-constraint rules for reusable modules.
# required_version and required_providers are injected by Terragrunt's
# root.hcl generate block at runtime — they must not live in the module
# source itself to avoid conflicts with Terragrunt's cache generation.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
