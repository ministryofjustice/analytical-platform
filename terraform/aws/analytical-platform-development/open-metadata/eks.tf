#tfsec:ignore:aws-eks-no-public-cluster-access
#tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
#tfsec:ignore:aws-eks-enable-control-plane-logging
#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "eks" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/eks/aws"
  version = "19.18.0"

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
    openmetadata-eks = {
      use_custom_launch_template = false
      launch_template_name       = ""
      min_size                   = 1
      max_size                   = 5
      desired_size               = 3
      disk_size                  = 150
      instance_types             = ["t3.2xlarge"]
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
