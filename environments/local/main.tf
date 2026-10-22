locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  environment          = var.environment
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  environment = var.environment
  project     = var.project
  tags        = local.common_tags
}
