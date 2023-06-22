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
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_driver_iam_role.iam_role_arn
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    main = {
      min_size       = 1
      max_size       = 10
      desired_size   = 5
      instance_types = ["t3.large"]
    }
  }

  fargate_profiles = {
    jupyterhub = {
      name                     = "jupyterhub"
      iam_role_name            = "jupyterhub-fargate"
      iam_role_use_name_prefix = true
      selectors = [
        {
          namespace = "jupyterhub"
          labels = {
            app = "jupyterhub"
          }
        }
      ]
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      groups   = ["system:masters"]
      rolearn  = "arn:aws:iam::525294151996:role/AWSReservedSSO_AdministratorAccess_675b01007c116a26"
      username = "administrator"
    }
  ]
}
