locals {
  name = "care-finder-${var.environment}"

  public_subnets  = { for i, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, 8, i) }
  private_subnets = { for i, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, 8, i + 10) }
}
