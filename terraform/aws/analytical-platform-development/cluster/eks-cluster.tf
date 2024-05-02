##################################################
# EKS cluster
##################################################

module "eks" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.eks_versions["cluster"]

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  enable_irsa = true

  map_roles = concat(
    [{
      groups   = ["system:masters"]
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${one(data.aws_iam_roles.aws_sso_administrator_access.names)}"
      username = "restricted-admin"
      }, {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }],
    var.eks_role_mappings
  )

  node_groups_defaults = {
    ami_type         = var.eks_node_group_ami_type
    disk_size        = var.eks_node_group_disk_size
    desired_capacity = var.eks_node_group_capacities["desired"]
    max_capacity     = var.eks_node_group_capacities["max"]
    min_capacity     = var.eks_node_group_capacities["min"]
    instance_types   = var.eks_node_group_instance_types
    version          = var.eks_versions["node-group"]
  }

  node_groups = {
    main_node_pool = {
      name_prefix                          = var.eks_node_group_name_prefix
      create_launch_template               = true
      metadata_http_endpoint               = "enabled"
      metadata_http_tokens                 = "required"
      metadata_http_put_response_hop_limit = 1
    }
    gpu_node_pool = {
      name_prefix            = var.eks_node_group_name_prefix
      create_launch_template = true

      ami_type       = var.eks_node_group_ami_type_gpu_node
      instance_types = var.eks_node_group_instance_types_gpu_node

      desired_capacity = var.eks_node_group_capacities_gpu_node["desired"]
      max_capacity     = var.eks_node_group_capacities_gpu_node["max"]
      min_capacity     = var.eks_node_group_capacities_gpu_node["min"]

      metadata_http_endpoint               = "enabled"
      metadata_http_tokens                 = "required"
      metadata_http_put_response_hop_limit = 1

      update_config = {
        max_unavailable = 1
      }

      taints = [
        {
          key    = "gpu-compute"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      k8s_labels = {
        gpu-compute = "true"
      }
    }
  }

  workers_additional_policies          = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  worker_additional_security_group_ids = [aws_security_group.allow_karpenter_communication.id]
  write_kubeconfig                     = false
}

resource "aws_security_group" "allow_karpenter_communication" {
  #checkov:skip=CKV2_AWS_5: skip not atttached to ec2
  description = " allows karpenter nodes  to communicate with infrastructure"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "allow_karpenter" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.karpenter.id
  security_group_id        = aws_security_group.allow_karpenter_communication.id
  description              = "allow karpenter"
}
