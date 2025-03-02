module "vpc_eks" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name = "${var.cluster_name}-vpc"

  cidr                  = var.vpc_cidr

  azs = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false


  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  propagate_private_route_tables_vgw = true
  propagate_public_route_tables_vgw  = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1",
    "mapPublicIpOnLaunch"             = "FALSE"
    "karpenter.sh/discovery"          = var.cluster_name
    "kubernetes.io/role/cni"          = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1",
    "mapPublicIpOnLaunch"    = "TRUE"
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}