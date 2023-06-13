##################################################
# General
##################################################

account_ids = {
  analytical-platform-management-production = "042130406152"
}

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "Management Cluster"
  environment            = "management"
  is-production          = "true"
  owner                  = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/analytical-platform-infrastructure"
}

##################################################
# Route53
##################################################

route53_zone = "management.analytical-platform.service.justice.gov.uk"

##################################################
# VPC
##################################################

vpc_cidr            = "10.70.0.0/16"
vpc_private_subnets = ["10.70.0.0/20", "10.70.16.0/20", "10.70.32.0/20"]
vpc_public_subnets  = ["10.70.48.0/20", "10.70.64.0/20", "10.70.80.0/20"]

##################################################
# EKS
##################################################

eks_versions = {
  cluster    = "1.24"
  node-group = "1.24"
}
eks_addon_versions = {
  coredns        = "v1.8.7-eksbuild.3"
  ebs-csi-driver = "v1.16.0-eksbuild.1"
  kube-proxy     = "v1.24.7-eksbuild.2"
  vpc-cni        = "v1.12.2-eksbuild.1"
}
eks_node_group_name_prefix = "mgmt"
eks_node_group_capacities = {
  desired = 8
  max     = 10
  min     = 3
}
eks_role_mappings = [
  {
    "rolearn" : "arn:aws:iam::525294151996:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::525294151996:role/github-actions-privileged",
    "username" : "github-actions-infrastructure",
    "groups" : ["system:masters", "system:bootstrappers"]
  },
  {
    "rolearn" : "arn:aws:iam::042130406152:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::312423030077:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::525294151996:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::312423030077:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::042130406152:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  }
]

eks_node_group_ami_type       = "AL2_x86_64"
eks_node_group_disk_size      = 250
eks_node_group_instance_types = ["r5.2xlarge"]
