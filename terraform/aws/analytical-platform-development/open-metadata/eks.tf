module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "open-metadata"
  cluster_version = "1.27"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    main = {
      min_size       = 1
      max_size       = 5
      desired_size   = 3
      instance_types = ["t3.large"]
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::525294151996:role/AdministratorAccess"
      username = "administrator"
      groups   = ["system:masters"]
    }
  ]
}
