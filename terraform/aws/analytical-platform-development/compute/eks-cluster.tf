module "eks" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.eks_cluster_name
  cluster_version = "1.29"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.intra_subnets
  subnet_ids               = module.vpc.private_subnets

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  cloudwatch_log_group_kms_key_id        = module.eks_cluster_logs_kms.key_arn
  cloudwatch_log_group_retention_in_days = 400
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_encryption_config = {
    resources = ["secrets"]
  }

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
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    # ami_release_version = local.environment_configuration.eks_versions.ami_release
    ami_type = "BOTTLEROCKET_x86_64"
    platform = "bottlerocket"
    metadata_options = {
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "required"
      instance_metadata_tags      = "enabled"
    }

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 100
        }
      }
    }

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  }

  // TODO: Review these settings
  eks_managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 5
      desired_size   = 3
      instance_types = ["t3.xlarge"]
    }
  }

  access_entries = {
    sso-administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.eks_sso_access_role.names)}"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

