#---------------------------------------------------------------
# use community module to create Kubernetes and EKS addons
#---------------------------------------------------------------

module "eks_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.4.0"

  eks_cluster_id               = module.eks.eks_cluster_id
  eks_cluster_endpoint         = module.eks.eks_cluster_endpoint
  eks_oidc_provider            = module.eks.oidc_provider
  eks_cluster_version          = module.eks.eks_cluster_version
  eks_worker_security_group_id = module.eks.worker_node_security_group_id

  enable_amazon_eks_coredns = true
  amazon_eks_coredns_config = {
    addon_version     = data.aws_eks_addon_version.latest["coredns"].version
    resolve_conflicts = "OVERWRITE"
  }
  enable_amazon_eks_kube_proxy = true
  amazon_eks_kube_proxy_config = {
    addon_version     = data.aws_eks_addon_version.default["kube-proxy"].version
    resolve_conflicts = "OVERWRITE"
  }
  enable_amazon_eks_vpc_cni            = true
   amazon_eks_vpc_cni_config = {
    addon_version     = data.aws_eks_addon_version.latest["vpc-cni"].version
    resolve_conflicts = "OVERWRITE"
  }
  enable_amazon_eks_aws_ebs_csi_driver = true
  amazon_eks_aws_ebs_csi_driver_config = {
    addon_version     = data.aws_eks_addon_version.latest["aws-ebs-csi-driver"].version
    resolve_conflicts = "OVERWRITE"
  }

  enable_aws_load_balancer_controller = true
  
  tags = local.tags

  depends_on = [
    module.vpc,
    module.eks.managed_node_groups
  ]
}

#---------------------------------------------------------------
# use community module to create VPC
#---------------------------------------------------------------
    
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway                             = true
  single_nat_gateway                             = true
  enable_dns_hostnames                           = true
  enable_ipv6                                    = true
  private_subnet_assign_ipv6_address_on_creation = true
  private_subnet_ipv6_prefixes                   = [0, 1, 2]

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}
